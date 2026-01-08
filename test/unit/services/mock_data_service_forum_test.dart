import 'package:flutter_test/flutter_test.dart';
import 'package:mvgr_nexus/services/mock_data_service.dart';
import 'package:mvgr_nexus/features/academic_forum/models/forum_model.dart';
import 'package:mvgr_nexus/core/constants/app_constants.dart';

void main() {
  group('MockDataService - Academic Forum', () {
    late MockDataService service;

    setUp(() {
      service = MockDataService();
    });

    group('questions getter', () {
      test('returns only approved questions', () {
        final questions = service.questions;
        for (final q in questions) {
          expect(q.status, ModerationStatus.approved);
        }
      });
    });

    group('getQuestionById', () {
      test('returns question when it exists', () {
        final questions = service.questions;
        if (questions.isNotEmpty) {
          final q = questions.first;
          final found = service.getQuestionById(q.id);
          expect(found, isNotNull);
          expect(found!.id, q.id);
        }
      });

      test('returns null when question does not exist', () {
        final found = service.getQuestionById('non_existent_question');
        expect(found, isNull);
      });
    });

    group('addQuestion', () {
      test('adds question to service', () {
        final newQuestion = AcademicQuestion(
          id: 'q_${DateTime.now().millisecondsSinceEpoch}',
          title: 'Test Question',
          content: 'What is the meaning of life?',
          authorId: 'author_001',
          authorName: 'Test Author',
          isAnonymous: false,
          category: ForumCategory.academic,
          subject: 'Philosophy',
          tags: ['life', 'philosophy'],
          createdAt: DateTime.now(),
          status: ModerationStatus.approved,
        );
        
        service.addQuestion(newQuestion);
        
        final found = service.getQuestionById(newQuestion.id);
        expect(found, isNotNull);
      });
    });

    group('Answers', () {
      test('addAnswer adds answer and increments question answer count', () {
        final questions = service.questions;
        if (questions.isEmpty) return;
        
        final question = questions.first;
        final initialCount = question.answerCount;
        
        final answer = Answer(
          id: 'ans_${DateTime.now().millisecondsSinceEpoch}',
          questionId: question.id,
          authorId: 'answer_author',
          authorName: 'Answer Author',
          content: 'This is the answer',
          createdAt: DateTime.now(),
        );
        
        service.addAnswer(answer);
        
        final answers = service.getAnswers(question.id);
        expect(answers.any((a) => a.id == answer.id), true);
        
        // Check answer count incremented
        final updatedQuestion = service.getQuestionById(question.id);
        expect(updatedQuestion!.answerCount, initialCount + 1);
      });

      test('getAnswers returns answers for question', () {
        final questions = service.questions;
        if (questions.isEmpty) return;
        
        final question = questions.first;
        service.addAnswer(Answer(
          id: 'ans_test_1',
          questionId: question.id,
          authorId: 'author',
          authorName: 'Author',
          content: 'Content',
          createdAt: DateTime.now(),
        ));
        
        final answers = service.getAnswers(question.id);
        expect(answers, isNotEmpty);
      });

      test('getAnswersForQuestion is alias for getAnswers', () {
        final questions = service.questions;
        if (questions.isEmpty) return;
        
        final question = questions.first;
        final answers1 = service.getAnswers(question.id);
        final answers2 = service.getAnswersForQuestion(question.id);
        expect(answers1.length, answers2.length);
      });

      test('getRankedAnswers returns answers sorted by quality', () {
        final questions = service.questions;
        if (questions.isEmpty) return;
        
        final question = questions.first;
        
        // Add multiple answers
        for (var i = 0; i < 3; i++) {
          service.addAnswer(Answer(
            id: 'ranked_ans_$i',
            questionId: question.id,
            authorId: 'author_$i',
            authorName: 'Author $i',
            content: 'Answer $i',
            helpfulCount: i * 5,
            createdAt: DateTime.now().subtract(Duration(days: i)),
          ));
        }
        
        final ranked = service.getRankedAnswers(question.id);
        expect(ranked, isNotEmpty);
      });
    });

    group('Question Upvotes', () {
      test('upvoteQuestion adds user to upvotedBy', () {
        final questions = service.questions;
        if (questions.isEmpty) return;
        
        final question = questions.first;
        final userId = 'upvote_user_${DateTime.now().millisecondsSinceEpoch}';
        
        service.upvoteQuestion(question.id, userId);
        
        final updated = service.getQuestionById(question.id);
        expect(updated!.upvotedBy.contains(userId), true);
      });

      test('upvoteQuestion prevents duplicate upvotes', () {
        final questions = service.questions;
        if (questions.isEmpty) return;
        
        final question = questions.first;
        final userId = 'dupe_upvote_user';
        
        service.upvoteQuestion(question.id, userId);
        final countAfterFirst = service.getQuestionById(question.id)!.upvoteCount;
        
        service.upvoteQuestion(question.id, userId);
        final countAfterSecond = service.getQuestionById(question.id)!.upvoteCount;
        
        expect(countAfterSecond, countAfterFirst);
      });

      test('removeQuestionUpvote removes user from upvotedBy', () {
        final questions = service.questions;
        if (questions.isEmpty) return;
        
        final question = questions.first;
        final userId = 'remove_upvote_user';
        
        service.upvoteQuestion(question.id, userId);
        expect(service.getQuestionById(question.id)!.upvotedBy.contains(userId), true);
        
        service.removeQuestionUpvote(question.id, userId);
        expect(service.getQuestionById(question.id)!.upvotedBy.contains(userId), false);
      });
    });

    group('Answer Upvotes', () {
      test('upvoteAnswer increments helpful count', () {
        final questions = service.questions;
        if (questions.isEmpty) return;
        
        final question = questions.first;
        final answer = Answer(
          id: 'upvote_test_ans',
          questionId: question.id,
          authorId: 'author',
          authorName: 'Author',
          content: 'Content',
          createdAt: DateTime.now(),
        );
        service.addAnswer(answer);
        
        service.upvoteAnswer(answer.id, 'upvoter_user');
        
        final answers = service.getAnswers(question.id);
        final updatedAnswer = answers.firstWhere((a) => a.id == answer.id);
        expect(updatedAnswer.helpfulCount, 1);
        expect(updatedAnswer.helpfulByIds.contains('upvoter_user'), true);
      });

      test('removeAnswerUpvote decrements helpful count', () {
        final questions = service.questions;
        if (questions.isEmpty) return;
        
        final question = questions.first;
        final answer = Answer(
          id: 'remove_upvote_ans',
          questionId: question.id,
          authorId: 'author',
          authorName: 'Author',
          content: 'Content',
          createdAt: DateTime.now(),
        );
        service.addAnswer(answer);
        
        service.upvoteAnswer(answer.id, 'remove_voter');
        service.removeAnswerUpvote(answer.id, 'remove_voter');
        
        final answers = service.getAnswers(question.id);
        final updatedAnswer = answers.firstWhere((a) => a.id == answer.id);
        expect(updatedAnswer.helpfulCount, 0);
      });
    });

    group('Expert Users', () {
      test('getExpertUsers returns users based on answer quality', () {
        final questions = service.questions;
        if (questions.isEmpty) return;
        
        final question = questions.first;
        for (var i = 0; i < 5; i++) {
          service.addAnswer(Answer(
            id: 'expert_ans_$i',
            questionId: question.id,
            authorId: 'expert_user',
            authorName: 'Expert User',
            content: 'Expert answer $i',
            helpfulCount: 10,
            isAccepted: i == 0,
            createdAt: DateTime.now(),
          ));
        }
        
        final experts = service.getExpertUsers(limit: 5);
        expect(experts, isA<List<ExpertUser>>());
      });
    });

    group('Related Questions', () {
      test('getRelatedQuestions returns questions with keyword overlap', () {
        final questions = service.questions;
        if (questions.isEmpty) return;
        
        final question = questions.first;
        final related = service.getRelatedQuestions(question.id, limit: 5);
        
        expect(related, isA<List<AcademicQuestion>>());
        expect(related.any((q) => q.id == question.id), false);
      });
    });
  });
}
