import 'package:flutter_test/flutter_test.dart';
import 'package:mvgr_nexus/features/academic_forum/models/forum_model.dart';

void main() {
  group('AcademicQuestion Model', () {
    test('creates question with required fields', () {
      final question = AcademicQuestion(
        id: '1',
        authorId: 'user_1',
        authorName: 'John Doe',
        isAnonymous: false,
        category: ForumCategory.academic,
        title: 'How to implement binary search?',
        content: 'I need help understanding binary search algorithm.',
        createdAt: DateTime.now(),
      );

      expect(question.id, '1');
      expect(question.title, 'How to implement binary search?');
      expect(question.category, ForumCategory.academic);
      expect(question.isAnonymous, false);
    });

    test('creates anonymous question', () {
      final question = AcademicQuestion(
        id: '1',
        isAnonymous: true,
        category: ForumCategory.academic,
        title: 'Question about exams',
        content: 'Sensitive topic',
        createdAt: DateTime.now(),
      );

      expect(question.isAnonymous, true);
      expect(question.displayAuthor, 'Anonymous');
    });

    test('question with subject and topic', () {
      final question = AcademicQuestion(
        id: '1',
        authorId: 'user_1',
        authorName: 'Student',
        isAnonymous: false,
        category: ForumCategory.academic,
        title: 'Recursion question',
        content: 'How does recursion work?',
        subject: 'Data Structures',
        topic: 'Recursion',
        createdAt: DateTime.now(),
      );

      expect(question.subject, 'Data Structures');
      expect(question.topic, 'Recursion');
    });

    test('question with tags', () {
      final question = AcademicQuestion(
        id: '1',
        authorId: 'user_1',
        authorName: 'Student',
        isAnonymous: false,
        category: ForumCategory.tech,
        title: 'Python list comprehension',
        content: 'How to use list comprehension?',
        tags: ['python', 'list', 'comprehension'],
        createdAt: DateTime.now(),
      );

      expect(question.tags, contains('python'));
      expect(question.tags.length, 3);
    });

    test('resolved question', () {
      final question = AcademicQuestion(
        id: '1',
        authorId: 'user_1',
        authorName: 'Student',
        isAnonymous: false,
        category: ForumCategory.academic,
        title: 'Solved question',
        content: 'This was answered',
        isResolved: true,
        acceptedAnswerId: 'answer_1',
        createdAt: DateTime.now(),
      );

      expect(question.isResolved, true);
      expect(question.acceptedAnswerId, 'answer_1');
    });

    test('question with engagement metrics', () {
      final question = AcademicQuestion(
        id: '1',
        authorId: 'user_1',
        authorName: 'Student',
        isAnonymous: false,
        category: ForumCategory.academic,
        title: 'Popular question',
        content: 'Many views',
        viewCount: 100,
        answerCount: 5,
        upvoteCount: 25,
        createdAt: DateTime.now(),
      );

      expect(question.viewCount, 100);
      expect(question.answerCount, 5);
      expect(question.upvoteCount, 25);
    });

    test('displayAuthor returns correct name for non-anonymous', () {
      final question = AcademicQuestion(
        id: '1',
        authorId: 'user_1',
        authorName: 'Test User',
        isAnonymous: false,
        title: 'Test',
        content: 'Content',
        createdAt: DateTime.now(),
      );

      expect(question.displayAuthor, 'Test User');
    });
  });

  group('ForumCategory', () {
    test('all categories are defined', () {
      expect(ForumCategory.values.length, 6);
    });

    test('academic category exists', () {
      expect(ForumCategory.values, contains(ForumCategory.academic));
    });

    test('tech category exists', () {
      expect(ForumCategory.values, contains(ForumCategory.tech));
    });

    test('career category exists', () {
      expect(ForumCategory.values, contains(ForumCategory.career));
    });

    test('campusLife category exists', () {
      expect(ForumCategory.values, contains(ForumCategory.campusLife));
    });

    test('fun category exists', () {
      expect(ForumCategory.values, contains(ForumCategory.fun));
    });

    test('displayName returns correct string', () {
      expect(ForumCategory.academic.displayName, 'Academic');
      expect(ForumCategory.career.displayName, 'Career & Placements');
      expect(ForumCategory.tech.displayName, 'Tech & Projects');
    });

    test('iconData returns non-null icon', () {
      for (final category in ForumCategory.values) {
        expect(category.iconData, isNotNull);
      }
    });

    test('color returns non-null color', () {
      for (final category in ForumCategory.values) {
        expect(category.color, isNotNull);
      }
    });
  });

  group('Answer Model', () {
    test('creates answer with required fields', () {
      final answer = Answer(
        id: '1',
        questionId: 'q1',
        authorId: 'user_1',
        authorName: 'Helper',
        content: 'Here is the solution...',
        createdAt: DateTime.now(),
      );

      expect(answer.id, '1');
      expect(answer.questionId, 'q1');
      expect(answer.content, 'Here is the solution...');
    });

    test('accepted answer', () {
      final answer = Answer(
        id: '1',
        questionId: 'q1',
        authorId: 'user_1',
        authorName: 'Expert',
        content: 'Best answer',
        isAccepted: true,
        createdAt: DateTime.now(),
      );

      expect(answer.isAccepted, true);
    });

    test('answer with helpful count', () {
      final answer = Answer(
        id: '1',
        questionId: 'q1',
        authorId: 'user_1',
        authorName: 'Helper',
        content: 'Helpful answer',
        helpfulCount: 10,
        createdAt: DateTime.now(),
      );

      expect(answer.helpfulCount, 10);
    });

    test('isHelpfulBy checks user ID', () {
      final answer = Answer(
        id: '1',
        questionId: 'q1',
        authorId: 'user_1',
        authorName: 'Helper',
        content: 'Answer',
        helpfulByIds: ['user_2', 'user_3'],
        createdAt: DateTime.now(),
      );

      expect(answer.isHelpfulBy('user_2'), true);
      expect(answer.isHelpfulBy('user_4'), false);
    });
  });

  group('Question Filtering', () {
    late List<AcademicQuestion> testQuestions;

    setUp(() {
      testQuestions = [
        AcademicQuestion(
          id: '1',
          authorId: 'u1',
          authorName: 'User1',
          isAnonymous: false,
          category: ForumCategory.academic,
          title: 'Math question',
          content: 'Help with calculus',
          answerCount: 0,
          createdAt: DateTime.now(),
        ),
        AcademicQuestion(
          id: '2',
          authorId: 'u2',
          authorName: 'User2',
          isAnonymous: false,
          category: ForumCategory.tech,
          title: 'Code question',
          content: 'Help with Python',
          answerCount: 3,
          isResolved: true,
          createdAt: DateTime.now(),
        ),
        AcademicQuestion(
          id: '3',
          authorId: 'u1',
          authorName: 'User1',
          isAnonymous: false,
          category: ForumCategory.academic,
          title: 'Physics question',
          content: 'Help with mechanics',
          answerCount: 1,
          createdAt: DateTime.now(),
        ),
      ];
    });

    test('filter by category', () {
      final academic = testQuestions
          .where((q) => q.category == ForumCategory.academic)
          .toList();
      expect(academic.length, 2);
    });

    test('filter unanswered questions', () {
      final unanswered = testQuestions
          .where((q) => q.answerCount == 0)
          .toList();
      expect(unanswered.length, 1);
      expect(unanswered.first.id, '1');
    });

    test('filter resolved questions', () {
      final resolved = testQuestions
          .where((q) => q.isResolved)
          .toList();
      expect(resolved.length, 1);
      expect(resolved.first.id, '2');
    });

    test('filter by author (my questions)', () {
      final myQuestions = testQuestions
          .where((q) => q.authorId == 'u1')
          .toList();
      expect(myQuestions.length, 2);
    });
  });

  group('Question Search', () {
    late List<AcademicQuestion> testQuestions;

    setUp(() {
      testQuestions = [
        AcademicQuestion(
          id: '1',
          authorId: 'u1',
          authorName: 'User1',
          isAnonymous: false,
          category: ForumCategory.academic,
          title: 'Binary Search Implementation',
          content: 'How to implement binary search in Python?',
          tags: ['python', 'search', 'algorithm'],
          createdAt: DateTime.now(),
        ),
        AcademicQuestion(
          id: '2',
          authorId: 'u2',
          authorName: 'User2',
          isAnonymous: false,
          category: ForumCategory.tech,
          title: 'Machine Learning basics',
          content: 'Getting started with ML in Python',
          tags: ['python', 'ml', 'ai'],
          createdAt: DateTime.now(),
        ),
      ];
    });

    test('search by title', () {
      final query = 'binary';
      final results = testQuestions
          .where((q) => q.title.toLowerCase().contains(query.toLowerCase()))
          .toList();
      expect(results.length, 1);
      expect(results.first.id, '1');
    });

    test('search by content', () {
      final query = 'Python';
      final results = testQuestions
          .where((q) => q.content.toLowerCase().contains(query.toLowerCase()))
          .toList();
      expect(results.length, 2);
    });

    test('search by tag', () {
      final tag = 'ml';
      final results = testQuestions
          .where((q) => q.tags.contains(tag))
          .toList();
      expect(results.length, 1);
      expect(results.first.id, '2');
    });
  });

  group('Question Sorting', () {
    test('sort by creation date (newest first)', () {
      final now = DateTime.now();
      final questions = [
        AcademicQuestion(
          id: '1',
          isAnonymous: false,
          category: ForumCategory.academic,
          title: 'Old',
          content: 'c',
          createdAt: now.subtract(const Duration(days: 2)),
        ),
        AcademicQuestion(
          id: '2',
          isAnonymous: false,
          category: ForumCategory.academic,
          title: 'New',
          content: 'c',
          createdAt: now,
        ),
      ];

      questions.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      expect(questions.first.id, '2');
    });

    test('sort by upvote count', () {
      final questions = [
        AcademicQuestion(
          id: '1',
          isAnonymous: false,
          category: ForumCategory.academic,
          title: 'Low votes',
          content: 'c',
          upvoteCount: 5,
          createdAt: DateTime.now(),
        ),
        AcademicQuestion(
          id: '2',
          isAnonymous: false,
          category: ForumCategory.academic,
          title: 'High votes',
          content: 'c',
          upvoteCount: 50,
          createdAt: DateTime.now(),
        ),
      ];

      questions.sort((a, b) => b.upvoteCount.compareTo(a.upvoteCount));
      
      expect(questions.first.id, '2');
    });
  });

  group('QuestionSubjects', () {
    test('all subjects are defined', () {
      expect(QuestionSubjects.all.length, greaterThan(0));
    });

    test('common subjects exist', () {
      expect(QuestionSubjects.all, contains('Mathematics'));
      expect(QuestionSubjects.all, contains('Computer Science'));
      expect(QuestionSubjects.all, contains('Physics'));
    });
  });

  group('Question serialization', () {
    test('toFirestore returns correct map', () {
      final question = AcademicQuestion(
        id: '1',
        authorId: 'user1',
        authorName: 'User',
        isAnonymous: false,
        category: ForumCategory.tech,
        title: 'Test Title',
        content: 'Test Content',
        subject: 'CS',
        createdAt: DateTime(2024, 1, 15),
      );

      final map = question.toFirestore();
      
      expect(map['title'], 'Test Title');
      expect(map['content'], 'Test Content');
      expect(map['category'], 'tech');
      expect(map['isAnonymous'], false);
    });

    test('fromFirestore creates correct object', () {
      final data = {
        'id': '1',
        'authorId': 'user1',
        'authorName': 'User',
        'isAnonymous': true,
        'category': 'career',
        'title': 'Career Question',
        'content': 'About placements',
        'viewCount': 50,
        'answerCount': 5,
        'createdAt': '2024-01-15T10:00:00.000Z',
      };

      final question = AcademicQuestion.fromFirestore(data);
      
      expect(question.title, 'Career Question');
      expect(question.category, ForumCategory.career);
      expect(question.isAnonymous, true);
      expect(question.viewCount, 50);
    });
  });

  group('Test Data', () {
    test('testQuestions provides sample data', () {
      final samples = AcademicQuestion.testQuestions;
      expect(samples.length, greaterThan(0));
    });

    test('testQuestions contain various categories', () {
      final samples = AcademicQuestion.testQuestions;
      final categories = samples.map((q) => q.category).toSet();
      expect(categories.length, greaterThan(1));
    });
  });
}
