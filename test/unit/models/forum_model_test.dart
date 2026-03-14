import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mvgr_nexus/features/academic_forum/models/forum_model.dart';

void main() {
  group('ForumCategory', () {
    test('has 6 values', () {
      expect(ForumCategory.values.length, 6);
    });

    test('displayName returns correct names', () {
      expect(ForumCategory.academic.displayName, 'Academic');
      expect(ForumCategory.career.displayName, 'Career & Placements');
      expect(ForumCategory.campusLife.displayName, 'Campus Life');
      expect(ForumCategory.tech.displayName, 'Tech & Projects');
      expect(ForumCategory.fun.displayName, 'Fun & Interests');
      expect(ForumCategory.other.displayName, 'Other');
    });

    test('iconData returns IconData', () {
      expect(ForumCategory.academic.iconData, Icons.school_rounded);
      expect(ForumCategory.career.iconData, Icons.work_rounded);
      expect(ForumCategory.campusLife.iconData, Icons.apartment_rounded);
      expect(ForumCategory.tech.iconData, Icons.code_rounded);
      expect(ForumCategory.fun.iconData, Icons.celebration_rounded);
      expect(ForumCategory.other.iconData, Icons.chat_bubble_rounded);
    });

    test('color returns Color for each category', () {
      expect(ForumCategory.academic.color, isA<Color>());
      expect(ForumCategory.career.color, isA<Color>());
      expect(ForumCategory.tech.color, isA<Color>());
    });
  });

  group('AcademicQuestion', () {
    late AcademicQuestion question;

    setUp(() {
      question = AcademicQuestion(
        id: 'q_001',
        authorId: 'user_001',
        authorName: 'John Doe',
        isAnonymous: false,
        title: 'How to solve differential equations?',
        content: 'Need help with Laplace transform',
        createdAt: DateTime.now(),
      );
    });

    group('constructor', () {
      test('creates question with required fields', () {
        expect(question.id, 'q_001');
        expect(question.authorId, 'user_001');
        expect(question.authorName, 'John Doe');
        expect(question.isAnonymous, false);
        expect(question.title, 'How to solve differential equations?');
      });

      test('default category is academic', () {
        expect(question.category, ForumCategory.academic);
      });

      test('default isResolved is false', () {
        expect(question.isResolved, false);
      });

      test('default viewCount is 0', () {
        expect(question.viewCount, 0);
      });

      test('default answerCount is 0', () {
        expect(question.answerCount, 0);
      });

      test('default upvoteCount is 0', () {
        expect(question.upvoteCount, 0);
      });

      test('default tags is empty', () {
        expect(question.tags, isEmpty);
      });
    });

    group('displayAuthor getter', () {
      test('returns author name when not anonymous', () {
        expect(question.displayAuthor, 'John Doe');
      });

      test('returns Anonymous when isAnonymous', () {
        final anonQuestion = AcademicQuestion(
          id: 'q_002',
          isAnonymous: true,
          title: 'Anonymous question',
          content: 'Content',
          createdAt: DateTime.now(),
        );
        expect(anonQuestion.displayAuthor, 'Anonymous');
      });

      test('returns Unknown when name is null and not anonymous', () {
        final noNameQuestion = AcademicQuestion(
          id: 'q_003',
          authorId: 'user_002',
          isAnonymous: false,
          title: 'No name question',
          content: 'Content',
          createdAt: DateTime.now(),
        );
        expect(noNameQuestion.displayAuthor, 'Unknown');
      });
    });

    group('copyWith', () {
      test('copies with new title', () {
        final copy = question.copyWith(title: 'New Title');
        expect(copy.title, 'New Title');
        expect(copy.id, question.id);
      });

      test('copies with new category', () {
        final copy = question.copyWith(category: ForumCategory.career);
        expect(copy.category, ForumCategory.career);
      });

      test('copies with isResolved', () {
        final copy = question.copyWith(isResolved: true);
        expect(copy.isResolved, true);
      });

      test('copies with new viewCount', () {
        final copy = question.copyWith(viewCount: 100);
        expect(copy.viewCount, 100);
      });

      test('copies with new tags', () {
        final copy = question.copyWith(tags: ['math', 'calculus']);
        expect(copy.tags, ['math', 'calculus']);
      });
    });

    group('toFirestore', () {
      test('returns correct map', () {
        final map = question.toFirestore();
        expect(map['authorId'], 'user_001');
        expect(map['authorName'], 'John Doe');
        expect(map['isAnonymous'], false);
        expect(map['category'], 'academic');
        expect(map['title'], 'How to solve differential equations?');
        expect(map['isResolved'], false);
      });
    });

    group('testQuestions', () {
      test('returns non-empty list', () {
        expect(AcademicQuestion.testQuestions, isNotEmpty);
      });

      test('test questions have different categories', () {
        final categories = AcademicQuestion.testQuestions
            .map((q) => q.category)
            .toSet();
        expect(categories.length, greaterThan(1));
      });
    });
  });

  group('Answer', () {
    late Answer answer;

    setUp(() {
      answer = Answer(
        id: 'a_001',
        questionId: 'q_001',
        authorId: 'user_002',
        authorName: 'Jane Doe',
        content: 'Here is the solution...',
        createdAt: DateTime.now(),
      );
    });

    group('constructor', () {
      test('creates answer with required fields', () {
        expect(answer.id, 'a_001');
        expect(answer.questionId, 'q_001');
        expect(answer.authorId, 'user_002');
        expect(answer.authorName, 'Jane Doe');
        expect(answer.content, 'Here is the solution...');
      });

      test('default isAccepted is false', () {
        expect(answer.isAccepted, false);
      });

      test('default helpfulCount is 0', () {
        expect(answer.helpfulCount, 0);
      });

      test('default helpfulByIds is empty', () {
        expect(answer.helpfulByIds, isEmpty);
      });

      test('editedAt is null by default', () {
        expect(answer.editedAt, isNull);
      });
    });

    group('isHelpfulBy', () {
      test('returns false when user has not marked helpful', () {
        expect(answer.isHelpfulBy('user_003'), false);
      });

      test('returns true when user has marked helpful', () {
        final markedAnswer = Answer(
          id: 'a_002',
          questionId: 'q_001',
          authorId: 'user_002',
          authorName: 'Jane',
          content: 'Answer',
          helpfulByIds: ['user_003', 'user_004'],
          createdAt: DateTime.now(),
        );
        expect(markedAnswer.isHelpfulBy('user_003'), true);
      });
    });

    group('toFirestore', () {
      test('returns correct map', () {
        final map = answer.toFirestore();
        expect(map['questionId'], 'q_001');
        expect(map['authorId'], 'user_002');
        expect(map['authorName'], 'Jane Doe');
        expect(map['content'], 'Here is the solution...');
        expect(map['isAccepted'], false);
        expect(map['helpfulCount'], 0);
      });
    });
  });

  group('QuestionSubjects', () {
    test('all contains expected subjects', () {
      expect(QuestionSubjects.all, contains('General'));
      expect(QuestionSubjects.all, contains('Mathematics'));
      expect(QuestionSubjects.all, contains('Computer Science'));
      expect(QuestionSubjects.all, contains('Data Structures'));
    });

    test('has at least 10 subjects', () {
      expect(QuestionSubjects.all.length, greaterThanOrEqualTo(10));
    });
  });
}
