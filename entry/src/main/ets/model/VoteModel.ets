export class HotVoteModel {
  id: number;
  subject: string;
  title: string;
  voteCount: number;
  confidence: number;
  stars: number;
  totalUsers: number;

  constructor(
    id: number,
    subject: string,
    title: string,
    voteCount: number,
    confidence: number,
    stars: number,
    totalUsers: number = 0
  ) {
    this.id = id;
    this.subject = subject;
    this.title = title;
    this.voteCount = voteCount;
    this.confidence = confidence;
    this.stars = stars;
    this.totalUsers = totalUsers;
  }

  computedConfidence(): number {
    if (this.totalUsers > 0) {
      return Math.round((this.voteCount / this.totalUsers) * 100);
    }
    return this.confidence;
  }

  confidencePercent(): string {
    return `${this.computedConfidence()}%`;
  }

  confidenceWidth(): number {
    return Math.max(5, Math.min(100, this.computedConfidence()));
  }

  starsText(): string {
    const filled = Math.min(5, Math.max(0, Math.round(this.stars)));
    return '★'.repeat(filled) + '☆'.repeat(5 - filled);
  }

  tagBg(): string {
    if (this.subject.indexOf('高数') >= 0 || this.subject.indexOf('数学') >= 0) return '#E8F0FF';
    if (this.subject.indexOf('线代') >= 0) return '#F5F0FF';
    if (this.subject.indexOf('数据结构') >= 0 || this.subject.indexOf('计算机') >= 0) return '#FFF7ED';
    return '#E6F7F5';
  }

  tagColor(): string {
    if (this.subject.indexOf('高数') >= 0 || this.subject.indexOf('数学') >= 0) return '#4A7FFF';
    if (this.subject.indexOf('线代') >= 0) return '#7330D1';
    if (this.subject.indexOf('数据结构') >= 0 || this.subject.indexOf('计算机') >= 0) return '#FF7E02';
    return '#38CFC9';
  }

  barColor(): string {
    if (this.subject.indexOf('高数') >= 0) return '#4A7FFF';
    if (this.subject.indexOf('线代') >= 0) return '#7330D1';
    if (this.subject.indexOf('数据结构') >= 0) return '#FF7E02';
    return '#38CFC9';
  }
}

@Observed
export class VoteItemModel {
  id: number;
  subject: string;
  title: string;
  description: string | null;
  voteCount: number;
  confidence: number;
  stars: number;
  hasVoted: boolean;

  constructor(
    id: number,
    subject: string,
    title: string,
    description: string | null,
    voteCount: number,
    confidence: number,
    stars: number,
    hasVoted: boolean
  ) {
    this.id = id;
    this.subject = subject;
    this.title = title;
    this.description = description;
    this.voteCount = voteCount;
    this.confidence = confidence;
    this.stars = stars;
    this.hasVoted = hasVoted;
  }

  toHotVote(): HotVoteModel {
    return new HotVoteModel(
      this.id, this.subject, this.title, this.voteCount, this.confidence, this.stars
    );
  }

  confidencePercent(): string {
    return `${this.confidence.toFixed(0)}%`;
  }

  confidenceWidth(): number {
    return Math.max(5, Math.min(100, this.confidence));
  }

  starsText(): string {
    const filled = Math.min(5, Math.max(0, Math.round(this.stars)));
    return '★'.repeat(filled) + '☆'.repeat(5 - filled);
  }

  tagBg(): string {
    if (this.subject.indexOf('高数') >= 0 || this.subject.indexOf('数学') >= 0) return '#E8F0FF';
    if (this.subject.indexOf('线代') >= 0) return '#F5F0FF';
    if (this.subject.indexOf('数据结构') >= 0 || this.subject.indexOf('计科') >= 0) return '#FFF7ED';
    return '#E6F7F5';
  }

  tagColor(): string {
    if (this.subject.indexOf('高数') >= 0) return '#4A7FFF';
    if (this.subject.indexOf('线代') >= 0) return '#7330D1';
    if (this.subject.indexOf('数据结构') >= 0) return '#FF7E02';
    return '#38CFC9';
  }

  barColor(): string {
    if (this.subject.indexOf('高数') >= 0) return '#4A7FFF';
    if (this.subject.indexOf('线代') >= 0) return '#7330D1';
    if (this.subject.indexOf('数据结构') >= 0) return '#FF7E02';
    return '#38CFC9';
  }
}

export class VoteListModel {
  list: VoteItemModel[];

  constructor(list: VoteItemModel[]) {
    this.list = list;
  }

  static empty(): VoteListModel {
    return new VoteListModel([]);
  }
}

export class MyVoteRecordModel {
  voteId: number;
  subject: string;
  title: string;
  voteCount: number;
  confidence: number;
  votedAt: string;
  myChoice: string; // '会考' | '不会考'

  constructor(
    voteId: number,
    subject: string,
    title: string,
    voteCount: number,
    confidence: number,
    votedAt: string,
    myChoice: string = '会考'
  ) {
    this.voteId = voteId;
    this.subject = subject;
    this.title = title;
    this.voteCount = voteCount;
    this.confidence = confidence;
    this.votedAt = votedAt;
    this.myChoice = myChoice;
  }

  confidencePercent(): string {
    return `${this.confidence.toFixed(1)}%`;
  }

  tagBg(): string {
    if (this.subject.indexOf('高数') >= 0 || this.subject.indexOf('数学') >= 0) return '#E8F0FF';
    if (this.subject.indexOf('线代') >= 0) return '#F5F0FF';
    return '#FFF7ED';
  }

  tagColor(): string {
    if (this.subject.indexOf('高数') >= 0) return '#4A7FFF';
    if (this.subject.indexOf('线代') >= 0) return '#7330D1';
    return '#FF7E02';
  }

  barColor(): string {
    if (this.subject.indexOf('高数') >= 0) return '#4A7FFF';
    if (this.subject.indexOf('线代') >= 0) return '#7330D1';
    return '#FF7E02';
  }
}

export class MyVoteListModel {
  list: MyVoteRecordModel[];

  constructor(list: MyVoteRecordModel[]) {
    this.list = list;
  }

  static empty(): MyVoteListModel {
    return new MyVoteListModel([]);
  }
}

export class MySubmissionModel {
  id: number;
  subject: string;
  title: string;
  description: string | null;
  status: string;
  createdAt: string;

  constructor(
    id: number,
    subject: string,
    title: string,
    description: string | null,
    status: string,
    createdAt: string
  ) {
    this.id = id;
    this.subject = subject;
    this.title = title;
    this.description = description;
    this.status = status;
    this.createdAt = createdAt;
  }

  isPending(): boolean {
    return this.status === '待审核';
  }

  isApproved(): boolean {
    return this.status === '已通过';
  }

  isRejected(): boolean {
    return this.status === '未通过';
  }

  statusChipBg(): string {
    if (this.isApproved()) return '#E6F7F5';
    if (this.isRejected()) return '#FFF0F0';
    return '#FFF7ED';
  }

  statusChipColor(): string {
    if (this.isApproved()) return '#38CFC9';
    if (this.isRejected()) return '#F54141';
    return '#FF7E02';
  }

  statusChipText(): string {
    if (this.isApproved()) return '✓ 已通过';
    if (this.isRejected()) return '✕ 未通过';
    return '⏳ 审核中';
  }
}

export class MySubmissionsModel {
  list: MySubmissionModel[];

  constructor(list: MySubmissionModel[]) {
    this.list = list;
  }

  static empty(): MySubmissionsModel {
    return new MySubmissionsModel([]);
  }
}

// 兼容旧命名
export { MySubmissionModel as SubmissionItemModel };

// SubmitVoteRequest 统一从 ApiService 引入，避免 ArkTS 结构化类型不兼容
export { SubmitVoteRequest } from '../api/ApiService';

export class SubmitVoteResultModel {
  id: number;
  subject: string;
  title: string;
  status: string;
  createdAt: string;
  message: string;

  constructor(
    id: number,
    subject: string,
    title: string,
    status: string,
    createdAt: string,
    message: string = ''
  ) {
    this.id = id;
    this.subject = subject;
    this.title = title;
    this.status = status;
    this.createdAt = createdAt;
    this.message = message;
  }
}

export class VoteResultModel {
  voteId: number;
  voteCount: number;
  confidence: number;

  constructor(voteId: number, voteCount: number, confidence: number) {
    this.voteId = voteId;
    this.voteCount = voteCount;
    this.confidence = confidence;
  }
}

export class PendingSubmissionModel {
  id: number;
  subject: string;
  title: string;
  description: string | null;
  status: string;
  createdAt: string;
  authorName: string;
  authorAvatar: string | null;

  constructor(
    id: number,
    subject: string,
    title: string,
    description: string | null,
    status: string,
    createdAt: string,
    authorName: string,
    authorAvatar: string | null
  ) {
    this.id = id;
    this.subject = subject;
    this.title = title;
    this.description = description;
    this.status = status;
    this.createdAt = createdAt;
    this.authorName = authorName;
    this.authorAvatar = authorAvatar;
  }

  tagBg(): string {
    if (this.subject.indexOf('高数') >= 0 || this.subject.indexOf('数学') >= 0) return '#E8F0FF';
    if (this.subject.indexOf('线代') >= 0) return '#F5F0FF';
    if (this.subject.indexOf('物理') >= 0) return '#FFF0F0';
    return '#FFF7ED';
  }

  tagColor(): string {
    if (this.subject.indexOf('高数') >= 0 || this.subject.indexOf('数学') >= 0) return '#4A7FFF';
    if (this.subject.indexOf('线代') >= 0) return '#7330D1';
    if (this.subject.indexOf('物理') >= 0) return '#F54141';
    return '#FF7E02';
  }
}

export class PendingSubmissionListModel {
  list: PendingSubmissionModel[];

  constructor(list: PendingSubmissionModel[]) {
    this.list = list;
  }

  static empty(): PendingSubmissionListModel {
    return new PendingSubmissionListModel([]);
  }
}
