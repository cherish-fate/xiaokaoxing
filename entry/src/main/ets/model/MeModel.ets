import { UserMeInfo } from '../api/ApiService';

@Observed
export class MeUserProfileModel {
  id: number;
  nickname: string;
  schoolName: string;
  majorId: number;
  majorName: string;
  avatarUrl: string | null;
  createdAt: string;

  constructor(
    id: number,
    nickname: string,
    schoolName: string,
    majorId: number,
    majorName: string,
    avatarUrl: string | null,
    createdAt: string
  ) {
    this.id = id;
    this.nickname = nickname;
    this.schoolName = schoolName;
    this.majorId = majorId;
    this.majorName = majorName;
    this.avatarUrl = avatarUrl;
    this.createdAt = createdAt;
  }

  static empty(): MeUserProfileModel {
    return new MeUserProfileModel(0, '同学', '某某大学', 0, '计算机科学与技术', null, '');
  }

  static fromApi(info: UserMeInfo): MeUserProfileModel {
    return new MeUserProfileModel(
      info.id || 0,
      info.nickname || '同学',
      info.school_name || '',
      info.major_id || 0,
      info.major_name || '',
      info.avatar_url || null,
      info.created_at || ''
    );
  }

  displayName(): string {
    return this.nickname && this.nickname.length > 0 ? this.nickname : '同学';
  }

  hasAvatar(): boolean {
    return !!this.avatarUrl && this.avatarUrl.length > 0;
  }

  subtitleText(): string {
    if (this.schoolName && this.majorName) {
      return `${this.schoolName} · ${this.majorName}`;
    }
    if (this.schoolName) {
      return this.schoolName;
    }
    return '完善学校与专业信息';
  }
}

@Observed
export class MeCheckinStatsModel {
  continuousDays: number;
  totalDays: number;
  rank: number;

  constructor(continuousDays: number, totalDays: number, rank: number) {
    this.continuousDays = continuousDays;
    this.totalDays = totalDays;
    this.rank = rank;
  }

  static empty(): MeCheckinStatsModel {
    return new MeCheckinStatsModel(0, 0, 0);
  }

  rankText(): string {
    return this.rank > 0 ? `#${this.rank}` : '--';
  }
}

@Observed
export class MeLearningStatsModel {
  notesCount: number;
  bookmarksCount: number;
  documentsCount: number;
  currentGpa: number;
  dailyQuestionCount: number;
  examSubjectsCount: number;

  constructor(
    notesCount: number,
    bookmarksCount: number,
    documentsCount: number,
    currentGpa: number,
    dailyQuestionCount: number,
    examSubjectsCount: number
  ) {
    this.notesCount = notesCount;
    this.bookmarksCount = bookmarksCount;
    this.documentsCount = documentsCount;
    this.currentGpa = currentGpa;
    this.dailyQuestionCount = dailyQuestionCount;
    this.examSubjectsCount = examSubjectsCount;
  }

  static empty(): MeLearningStatsModel {
    return new MeLearningStatsModel(0, 0, 0, 0, 0, 0);
  }

  gpaDisplay(): string {
    return this.currentGpa > 0 ? this.currentGpa.toFixed(1) : '--';
  }
}

@Observed
export class MeContentCountsModel {
  uploadsCount: number;
  votesCount: number;
  submissionsCount: number;
  teamsCount: number;

  constructor(
    uploadsCount: number,
    votesCount: number,
    submissionsCount: number,
    teamsCount: number
  ) {
    this.uploadsCount = uploadsCount;
    this.votesCount = votesCount;
    this.submissionsCount = submissionsCount;
    this.teamsCount = teamsCount;
  }

  static empty(): MeContentCountsModel {
    return new MeContentCountsModel(0, 0, 0, 0);
  }
}

@Observed
export class MeNotificationSettingsModel {
  examReminder: boolean;
  checkinReminder: boolean;

  constructor(examReminder: boolean, checkinReminder: boolean) {
    this.examReminder = examReminder;
    this.checkinReminder = checkinReminder;
  }

  static empty(): MeNotificationSettingsModel {
    return new MeNotificationSettingsModel(true, true);
  }

  descriptionText(): string {
    const parts: string[] = [];
    parts.push(this.examReminder ? '考试提醒已开' : '考试提醒已关');
    parts.push(this.checkinReminder ? '打卡提醒已开' : '打卡提醒已关');
    return parts.join(' · ');
  }
}

@Observed
export class MeAboutInfoModel {
  version: string;
  appName: string;
  description: string;
  team: string;
  website: string;
  supportEmail: string;
  privacyUrl: string;
  termsUrl: string;
  copyright: string;

  constructor(
    version: string,
    appName: string,
    description: string,
    team?: string,
    website?: string,
    supportEmail?: string,
    privacyUrl?: string,
    termsUrl?: string,
    copyright?: string
  ) {
    this.version = version;
    this.appName = appName;
    this.description = description;
    this.team = team || '校考星团队';
    this.website = website || 'https://www.xiaokaoxing.com';
    this.supportEmail = supportEmail || 'support@xiaokaoxing.com';
    this.privacyUrl = privacyUrl || '';
    this.termsUrl = termsUrl || '';
    this.copyright = copyright || '© 2026 校考星团队 · 保留所有权利';
  }

  static empty(): MeAboutInfoModel {
    return new MeAboutInfoModel(
      'v1.0.0',
      '校考星',
      '校考星是一款专为在校生打造的学习备考助手，集考试管理、任务规划、资料共享、社区互动于一体，帮你高效备战校考。',
      '校考星团队',
      'https://www.xiaokaoxing.com',
      'support@xiaokaoxing.com',
      '',
      '',
      '@ 2026 校考星团队 · 保留所有权利'
    );
  }

  versionDisplay(): string {
    return `版本 ${this.version}`;
  }
}

@Observed
export class MePageModel {
  user: MeUserProfileModel;
  checkin: MeCheckinStatsModel;
  learning: MeLearningStatsModel;
  contentCounts: MeContentCountsModel;
  notificationSettings: MeNotificationSettingsModel;
  about: MeAboutInfoModel;

  constructor(
    user: MeUserProfileModel,
    checkin: MeCheckinStatsModel,
    learning: MeLearningStatsModel,
    contentCounts: MeContentCountsModel,
    notificationSettings: MeNotificationSettingsModel,
    about: MeAboutInfoModel
  ) {
    this.user = user;
    this.checkin = checkin;
    this.learning = learning;
    this.contentCounts = contentCounts;
    this.notificationSettings = notificationSettings;
    this.about = about;
  }

  static empty(): MePageModel {
    return new MePageModel(
      MeUserProfileModel.empty(),
      MeCheckinStatsModel.empty(),
      MeLearningStatsModel.empty(),
      MeContentCountsModel.empty(),
      MeNotificationSettingsModel.empty(),
      MeAboutInfoModel.empty()
    );
  }
}
