import { DateUtil } from '../utils/DateUtil';

export class ExamModel {
  id: number;
  name: string;
  examDate: string;
  startTime: string;
  endTime: string;
  location: string;
  isCompleted: boolean;
  daysRemaining: number;
  daysText: string;
  status: string;

  constructor(
    id: number,
    name: string,
    examDate: string,
    startTime: string,
    endTime: string,
    location: string,
    isCompleted: boolean,
    daysRemaining: number,
    daysText: string,
    status: string
  ) {
    this.id = id;
    this.name = name;
    this.examDate = examDate;
    this.startTime = startTime;
    this.endTime = endTime;
    this.location = location;
    this.isCompleted = isCompleted;
    this.daysRemaining = daysRemaining;
    this.daysText = daysText;
    this.status = status;
  }

  timeRangeText(): string {
    return DateUtil.timeRangeText(this.startTime, this.endTime);
  }

  timeTextWithDate(): string {
    return `${this.examDate} ${this.startTime}`;
  }

  isExpired(): boolean {
    return this.daysRemaining < 0;
  }

  isToday(): boolean {
    return this.daysRemaining === 0;
  }

  hasLocation(): boolean {
    return !!this.location;
  }
}

export class ExamCountdownModel {
  hasExam: boolean;
  examName: string;
  examDate: string;
  startTime: string;
  endTime: string;
  countdownDays: number;
  countdownText: string;

  constructor(
    hasExam: boolean,
    examName: string,
    examDate: string,
    startTime: string,
    endTime: string,
    countdownDays: number,
    countdownText: string
  ) {
    this.hasExam = hasExam;
    this.examName = examName;
    this.examDate = examDate;
    this.startTime = startTime;
    this.endTime = endTime;
    this.countdownDays = countdownDays;
    this.countdownText = countdownText;
  }

  timeRangeText(): string {
    return DateUtil.timeRangeText(this.startTime, this.endTime);
  }
}

export class TodayProgressModel {
  completed: number;
  total: number;
  progressPercentage: number;

  constructor(completed: number, total: number, progressPercentage: number) {
    this.completed = completed;
    this.total = total;
    this.progressPercentage = progressPercentage;
  }

  static computeProgress(completed: number, total: number): number {
    if (total <= 0) {
      return 0;
    }
    return Math.floor((completed / total) * 100);
  }
}
