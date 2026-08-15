import {
  DailyQuestionToday,
  DailyAnsweredRecord,
  SubmitDailyAnswerData
} from '../api/ApiService';

@Observed
export class DailyQuestionModel {
  id: number;
  subject: string;
  question: string;
  options: string[];
  difficulty: number;
  date: string;
  hasAnswered: boolean;
  record: DailyAnsweredRecord | null;

  constructor(
    id: number = 0,
    subject: string = '',
    question: string = '',
    options: string[] = [],
    difficulty: number = 1,
    date: string = '',
    hasAnswered: boolean = false,
    record: DailyAnsweredRecord | null = null
  ) {
    this.id = id;
    this.subject = subject;
    this.question = question;
    this.options = options;
    this.difficulty = difficulty;
    this.date = date;
    this.hasAnswered = hasAnswered;
    this.record = record;
  }

  static empty(): DailyQuestionModel {
    return new DailyQuestionModel();
  }

  static fromApi(src: DailyQuestionToday): DailyQuestionModel {
    return new DailyQuestionModel(
      src.id || 0,
      src.subject || '',
      src.question || '',
      src.options || [],
      src.difficulty || 1,
      src.date || '',
      !!src.has_answered,
      src.record || null
    );
  }

  difficultyLabel(): string {
    if (this.difficulty <= 1) return '简单';
    if (this.difficulty === 2) return '中等';
    return '困难';
  }

  difficultyStars(): string {
    const total: number = 3;
    const filled: number = Math.min(this.difficulty, total);
    let result: string = '';
    for (let i: number = 0; i < total; i++) {
      result += i < filled ? '★' : '☆';
    }
    return result;
  }

  optionLabels(): string[] {
    const labels: string[] = ['A', 'B', 'C', 'D', 'E', 'F'];
    return this.options.map((_, i) => labels[i] || String(i + 1));
  }

  getRecordSelected(): string {
    return this.record ? this.record.selected : '';
  }

  getRecordIsCorrect(): boolean {
    return this.record ? this.record.is_correct : false;
  }

  getRecordExplanation(): string {
    return this.record ? this.record.explanation : '';
  }
}

@Observed
export class DailyQuestionResultModel {
  isCorrect: boolean;
  correctAnswer: string;
  explanation: string;
  earnedPoints: number;
  wrongBookAdded: boolean;

  constructor(
    isCorrect: boolean = false,
    correctAnswer: string = '',
    explanation: string = '',
    earnedPoints: number = 0,
    wrongBookAdded: boolean = false
  ) {
    this.isCorrect = isCorrect;
    this.correctAnswer = correctAnswer;
    this.explanation = explanation;
    this.earnedPoints = earnedPoints;
    this.wrongBookAdded = wrongBookAdded;
  }

  static empty(): DailyQuestionResultModel {
    return new DailyQuestionResultModel();
  }

  static fromApi(src: SubmitDailyAnswerData): DailyQuestionResultModel {
    return new DailyQuestionResultModel(
      !!src.is_correct,
      src.correct_answer || '',
      src.explanation || '',
      src.earned_points || 0,
      !!src.wrong_book_added
    );
  }

  static fromRecord(record: DailyAnsweredRecord): DailyQuestionResultModel {
    return new DailyQuestionResultModel(
      !!record.is_correct,
      '',
      record.explanation || '',
      0,
      false
    );
  }
}
