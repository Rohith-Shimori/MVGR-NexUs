import '../config/supabase_config.dart';
import 'package:flutter/foundation.dart';
import '../core/utils/logger.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../features/academic_forum/models/forum_model.dart';


class SupabaseForumService extends ChangeNotifier {
  static final SupabaseForumService _instance = SupabaseForumService._internal();
  static SupabaseForumService get instance => _instance;
  factory SupabaseForumService() => _instance;

  SupabaseForumService._internal() {
    _init();
  }

  final SupabaseClient _supabase = Supabase.instance.client;
  
  List<AcademicQuestion> _questions = [];
  bool _isLoading = false;
  String? _error;

  List<AcademicQuestion> get questions => _questions;
  bool get isLoading => _isLoading;
  String? get error => _error;

  void _init() {
    // Lazy loading - questions fetched on demand
  }

  /// Fetch questions with filters
  Future<void> fetchQuestions({
    ForumCategory? category,
    String? searchQuery,
    String? filter, // 'unanswered', 'resolved', 'my_questions'
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      var query = _supabase.from(SupabaseTables.forumQuestions).select();

      if (category != null) {
        query = query.eq('category', category.name);
      }
      
      if (searchQuery != null && searchQuery.isNotEmpty) {
        query = query.or('title.ilike.%$searchQuery%,content.ilike.%$searchQuery%');
      }

      final userId = _supabase.auth.currentUser?.id ?? '';
      if (filter == 'my_questions' && userId.isNotEmpty) {
        query = query.eq('author_id', userId);
      } else if (filter == 'unanswered') {
        query = query.eq('answer_count', 0);
      } else if (filter == 'resolved') {
        query = query.eq('is_resolved', true);
      }

      final response = await query.order('created_at', ascending: false);
      
      _questions = (response as List).map((json) {
        return _mapToQuestion(json);
      }).toList();

    } catch (e) {
      _error = e.toString();
      AppLogger.error('Error fetching questions: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Map Supabase snake_case to Model
  AcademicQuestion _mapToQuestion(Map<String, dynamic> json) {
    return AcademicQuestion(
      id: json['id'].toString(),
      authorId: json['author_id'],
      authorName: json['author_name'],
      isAnonymous: json['is_anonymous'] ?? false,
      category: ForumCategory.values.firstWhere(
        (c) => c.name == json['category'],
        orElse: () => ForumCategory.academic,
      ),
      title: json['title'],
      content: json['content'],
      subject: json['subject'] ?? '',
      topic: json['topic'] ?? '',
      tags: List<String>.from(json['tags'] ?? []),
      isResolved: json['is_resolved'] ?? false,
      acceptedAnswerId: json['accepted_answer_id'],
      viewCount: json['view_count'] ?? 0,
      answerCount: json['answer_count'] ?? 0,
      upvoteCount: json['upvote_count'] ?? 0,
      createdAt: DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now(),
      imageUrl: json['image_url'],
    );
  }

  Future<void> addQuestion(AcademicQuestion question) async {
    try {
      await _supabase.from(SupabaseTables.forumQuestions).insert({
        'title': question.title,
        'content': question.content,
        'category': question.category.name,
        'subject': question.subject,
        'topic': question.topic,
        'tags': question.tags,
        'author_id': question.authorId,
        'author_name': question.authorName,
        'is_anonymous': question.isAnonymous,
        'created_at': DateTime.now().toIso8601String(),
        'view_count': 0,
        'answer_count': 0,
        'upvote_count': 0,
        'image_url': question.imageUrl,
        'is_resolved': false,
      });
      await fetchQuestions();
    } catch (e) {
      AppLogger.error('Error adding question: $e');
      rethrow;
    }
  }

  /// Get answers for a question
  Future<List<Answer>> getAnswers(String questionId) async {
    try {
      final response = await _supabase
          .from(SupabaseTables.forumAnswers)
          .select()
          .eq('question_id', questionId)
          .order('created_at', ascending: true);
          
      return (response as List).map((json) => Answer(
        id: json['id'].toString(),
        questionId: json['question_id'],
        authorId: json['author_id'],
        authorName: json['author_name'],
        content: json['content'],
        isAccepted: json['is_accepted'] ?? false,
        helpfulCount: json['helpful_count'] ?? 0,
        createdAt: DateTime.parse(json['created_at']),
      )).toList();
    } catch (e) {
      AppLogger.error('Error fetching answers: $e');
      return [];
    }
  }

  Future<void> addAnswer(String questionId, String content, bool isAnonymous) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('Must be logged in');

    try {
      await _supabase.from(SupabaseTables.forumAnswers).insert({
        'question_id': questionId,
        'author_id': user.id,
        'author_name': isAnonymous ? 'Anonymous' : (user.userMetadata?['name'] ?? 'User'),
        'content': content,
        'created_at': DateTime.now().toIso8601String(),
        'helpful_count': 0,
        'is_accepted': false,
      });
      
      // Increment answer count via RPC if available, else manual
      try {
        await _supabase.rpc('increment_forum_answer_count', params: {'question_id': questionId});
      } catch (e) {
        // RPC might not exist - log but don't fail
        AppLogger.warning(' increment_forum_answer_count RPC failed: $e');
      }
      
      notifyListeners();
    } catch (e) {
      AppLogger.error('Error adding answer: $e');
      rethrow;
    }
  }

  Future<void> upvoteQuestion(String questionId) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    try {
      // Check if already upvoted
      final existing = await _supabase
          .from(SupabaseTables.forumVotes)
          .select()
          .match({
            'user_id': user.id,
            'item_id': questionId,
            'type': 'question_upvote'
          })
          .maybeSingle();

      if (existing != null) {
        // Remove vote
        await _supabase.from(SupabaseTables.forumVotes).delete().eq('id', existing['id']);
        await _supabase.rpc('decrement_forum_upvote', params: {'question_id': questionId});
      } else {
        // Add vote
        await _supabase.from(SupabaseTables.forumVotes).insert({
          'user_id': user.id,
          'item_id': questionId,
          'type': 'question_upvote'
        });
        await _supabase.rpc('increment_forum_upvote', params: {'question_id': questionId});
      }
    } catch (e) {
      AppLogger.error('Error upvoting: $e');
    }
  }
  Future<void> upvoteAnswer(String answerId) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    try {
      // Check if already upvoted
      final existing = await _supabase
          .from(SupabaseTables.forumVotes)
          .select()
          .match({
            'user_id': user.id,
            'item_id': answerId,
            'type': 'answer_upvote'
          })
          .maybeSingle();

      if (existing != null) {
        // Remove vote
        await _supabase.from(SupabaseTables.forumVotes).delete().eq('id', existing['id']);
        try {
          await _supabase.rpc('decrement_forum_answer_upvote', params: {'answer_id': answerId});
        } catch (e) {
          AppLogger.warning(' decrement_forum_answer_upvote RPC failed: $e');
        }
      } else {
        // Add vote
        await _supabase.from(SupabaseTables.forumVotes).insert({
          'user_id': user.id,
          'item_id': answerId,
          'type': 'answer_upvote'
        });
        try {
          await _supabase.rpc('increment_forum_answer_upvote', params: {'answer_id': answerId});
        } catch (e) {
          AppLogger.warning(' increment_forum_answer_upvote RPC failed: $e');
        }
      }
    } catch (e) {
      AppLogger.error('Error upvoting answer: $e');
    }
  }
}