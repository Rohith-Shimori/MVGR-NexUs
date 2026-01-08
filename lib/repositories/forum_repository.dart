/// Forum Repository - Handles academic forum data operations
library;

import '../core/errors/result.dart';
import '../core/errors/app_exception.dart';
import '../features/academic_forum/models/forum_model.dart';
import '../config/supabase_config.dart';
import 'base_repository.dart';

/// Helper to build AcademicQuestion from JSON map
AcademicQuestion _questionFromJson(Map<String, dynamic> json) {
  return AcademicQuestion(
    id: json['id'] ?? '',
    authorId: json['author_id'],
    authorName: json['author_name'],
    isAnonymous: json['is_anonymous'] ?? false,
    category: ForumCategory.values.firstWhere(
      (c) => c.name == json['category'],
      orElse: () => ForumCategory.academic,
    ),
    title: json['title'] ?? '',
    content: json['content'] ?? '',
    subject: json['subject'] ?? '',
    topic: json['topic'] ?? '',
    tags: List<String>.from(json['tags'] ?? []),
    isResolved: json['is_resolved'] ?? false,
    acceptedAnswerId: json['accepted_answer_id'],
    viewCount: json['view_count'] ?? 0,
    answerCount: json['answer_count'] ?? 0,
    upvoteCount: json['upvote_count'] ?? 0,
    upvotedBy: List<String>.from(json['upvoted_by'] ?? []),
    createdAt: json['created_at'] != null 
        ? DateTime.parse(json['created_at']) 
        : DateTime.now(),
  );
}

/// Helper to build Answer from JSON map
Answer _answerFromJson(Map<String, dynamic> json) {
  return Answer(
    id: json['id'] ?? '',
    questionId: json['question_id'] ?? '',
    authorId: json['author_id'] ?? '',
    authorName: json['author_name'] ?? '',
    content: json['content'] ?? '',
    isAccepted: json['is_accepted'] ?? false,
    helpfulCount: json['helpful_count'] ?? 0,
    helpfulByIds: List<String>.from(json['helpful_by_ids'] ?? []),
    createdAt: json['created_at'] != null 
        ? DateTime.parse(json['created_at']) 
        : DateTime.now(),
  );
}

/// Repository for Forum Questions
class ForumQuestionRepository extends BaseRepository<AcademicQuestion> {
  @override
  String get tableName => SupabaseTables.forumQuestions;

  @override
  Map<String, dynamic> toJson(AcademicQuestion model) => model.toFirestore();

  @override
  AcademicQuestion fromJson(Map<String, dynamic> json) => _questionFromJson(json);

  @override
  String getId(AcademicQuestion model) => model.id;

  /// Get questions by category
  Future<Result<List<AcademicQuestion>>> getByCategory(ForumCategory category) async {
    return getByField('category', category.name);
  }

  /// Get questions by subject
  Future<Result<List<AcademicQuestion>>> getBySubject(String subject) async {
    return getByField('subject', subject);
  }

  /// Get trending questions (most upvotes)
  Future<Result<List<AcademicQuestion>>> getTrending({int limit = 10}) async {
    return runCatchingAsync(() async {
      final response = await client
          .from(tableName)
          .select()
          .order('upvote_count', ascending: false)
          .limit(limit);

      return (response as List).map((e) => fromJson(e as Map<String, dynamic>)).toList();
    });
  }

  /// Get unanswered questions
  Future<Result<List<AcademicQuestion>>> getUnanswered() async {
    return runCatchingAsync(() async {
      final response = await client
          .from(tableName)
          .select()
          .eq('answer_count', 0)
          .order('created_at', ascending: false);

      return (response as List).map((e) => fromJson(e as Map<String, dynamic>)).toList();
    });
  }

  /// Get resolved questions
  Future<Result<List<AcademicQuestion>>> getResolved() async {
    return runCatchingAsync(() async {
      final response = await client
          .from(tableName)
          .select()
          .eq('is_resolved', true)
          .order('created_at', ascending: false);

      return (response as List).map((e) => fromJson(e as Map<String, dynamic>)).toList();
    });
  }

  /// Upvote a question
  Future<Result<void>> upvote(String questionId, String userId) async {
    return runCatchingAsync(() async {
      final result = await getById(questionId);
      final question = result.valueOrNull;
      
      if (question == null) {
        throw DataException.notFound('Question');
      }

      final updatedUpvotes = [...question.upvotedBy, userId];
      await client.from(tableName).update({
        'upvoted_by': updatedUpvotes,
        'upvote_count': updatedUpvotes.length,
      }).eq('id', questionId);
    });
  }

  /// Increment view count
  Future<Result<void>> incrementViews(String questionId) async {
    return runCatchingAsync(() async {
      await client.rpc('increment_view_count', params: {'question_id': questionId});
    });
  }

  /// Search questions
  Future<Result<List<AcademicQuestion>>> search(String query) async {
    return runCatchingAsync(() async {
      final response = await client
          .from(tableName)
          .select()
          .or('title.ilike.%$query%,content.ilike.%$query%')
          .limit(20);

      return (response as List).map((e) => fromJson(e as Map<String, dynamic>)).toList();
    });
  }

  /// Mark as resolved
  Future<Result<void>> markResolved(String questionId, String acceptedAnswerId) async {
    return runCatchingAsync(() async {
      await client.from(tableName).update({
        'is_resolved': true,
        'accepted_answer_id': acceptedAnswerId,
      }).eq('id', questionId);
    });
  }
}

/// Repository for Forum Answers
class ForumAnswerRepository extends BaseRepository<Answer> {
  @override
  String get tableName => SupabaseTables.forumAnswers;

  @override
  Map<String, dynamic> toJson(Answer model) => model.toFirestore();

  @override
  Answer fromJson(Map<String, dynamic> json) => _answerFromJson(json);

  @override
  String getId(Answer model) => model.id;

  /// Get answers for a question
  Future<Result<List<Answer>>> getForQuestion(String questionId) async {
    return runCatchingAsync(() async {
      final response = await client
          .from(tableName)
          .select()
          .eq('question_id', questionId)
          .order('helpful_count', ascending: false);

      return (response as List).map((e) => fromJson(e as Map<String, dynamic>)).toList();
    });
  }

  /// Mark as helpful
  Future<Result<void>> markHelpful(String answerId, String userId) async {
    return runCatchingAsync(() async {
      final result = await getById(answerId);
      final answer = result.valueOrNull;
      
      if (answer == null) {
        throw DataException.notFound('Answer');
      }

      final updatedHelpful = [...answer.helpfulByIds, userId];
      await client.from(tableName).update({
        'helpful_by_ids': updatedHelpful,
        'helpful_count': updatedHelpful.length,
      }).eq('id', answerId);
    });
  }

  /// Mark as accepted
  Future<Result<void>> markAccepted(String answerId) async {
    return runCatchingAsync(() async {
      await client.from(tableName).update({
        'is_accepted': true,
      }).eq('id', answerId);
    });
  }
}
