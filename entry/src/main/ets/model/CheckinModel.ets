export class CheckinStatsModel {
  totalDays: number;
  continuousDays: number;
  rank: number;
  checkedWeekDays: number[];

  constructor(totalDays: number, continuousDays: number, rank: number, checkedWeekDays: number[] = []) {
    this.totalDays = totalDays;
    this.continuousDays = continuousDays;
    this.rank = rank;
    this.checkedWeekDays = checkedWeekDays;
  }

  static empty(): CheckinStatsModel {
    return new CheckinStatsModel(0, 0, 0, []);
  }
}

export class CheckinRecordModel {
  id: number;
  subjects: string[];
  duration: string;
  note: string;
  tags: string[];

  constructor(
    id: number,
    subjects: string[],
    duration: string,
    note: string,
    tags: string[]
  ) {
    this.id = id;
    this.subjects = subjects;
    this.duration = duration;
    this.note = note;
    this.tags = tags;
  }

  static empty(): CheckinRecordModel {
    return new CheckinRecordModel(0, [], '', '', []);
  }
}

export class TodayCheckinModel {
  hasCheckedIn: boolean;
  continuousDays: number;
  totalDays: number;
  rank: number;
  checkinRecord: CheckinRecordModel | null;

  constructor(
    hasCheckedIn: boolean,
    continuousDays: number,
    totalDays: number,
    rank: number,
    checkinRecord: CheckinRecordModel | null
  ) {
    this.hasCheckedIn = hasCheckedIn;
    this.continuousDays = continuousDays;
    this.totalDays = totalDays;
    this.rank = rank;
    this.checkinRecord = checkinRecord;
  }

  static empty(): TodayCheckinModel {
    return new TodayCheckinModel(false, 0, 0, 0, null);
  }
}

// 兼容旧命名
export { TodayCheckinModel as TodayCheckinStatusModel };

export class CalendarDayModel {
  date: string;
  day: number;
  isChecked: boolean;
  isToday: boolean;

  constructor(date: string, day: number, isChecked: boolean, isToday: boolean) {
    this.date = date;
    this.day = day;
    this.isChecked = isChecked;
    this.isToday = isToday;
  }
}

export class CheckinCalendarModel {
  year: number;
  month: number;
  days: CalendarDayModel[];

  constructor(year: number, month: number, days: CalendarDayModel[]) {
    this.year = year;
    this.month = month;
    this.days = days;
  }

  static empty(): CheckinCalendarModel {
    const now = new Date();
    return new CheckinCalendarModel(now.getFullYear(), now.getMonth() + 1, []);
  }
}

export class RankUserModel {
  rank: number;
  userId: number;
  nickname: string;
  avatarUrl: string | null;
  continuousDays: number;
  totalDays: number;
  isMe: boolean;

  constructor(
    rank: number,
    userId: number,
    nickname: string,
    avatarUrl: string | null,
    continuousDays: number,
    totalDays: number,
    isMe: boolean = false
  ) {
    this.rank = rank;
    this.userId = userId;
    this.nickname = nickname;
    this.avatarUrl = avatarUrl;
    this.continuousDays = continuousDays;
    this.totalDays = totalDays;
    this.isMe = isMe;
  }
}

export class RankingModel {
  list: RankUserModel[];
  myRank: RankUserModel;

  constructor(list: RankUserModel[], myRank: RankUserModel) {
    this.list = list;
    this.myRank = myRank;
  }

  static empty(): RankingModel {
    const emptyUser = new RankUserModel(0, 0, '我', null, 0, 0, true);
    return new RankingModel([], emptyUser);
  }
}

// 兼容旧命名
export { RankingModel as CheckinRankingModel };

export class CheckinSubmitResultModel {
  id: number;
  checkinDate: string;
  continuousDays: number;
  totalDays: number;
  earnedPoints: number;
  message: string;

  constructor(
    id: number,
    checkinDate: string,
    continuousDays: number,
    totalDays: number,
    earnedPoints: number,
    message: string = ''
  ) {
    this.id = id;
    this.checkinDate = checkinDate;
    this.continuousDays = continuousDays;
    this.totalDays = totalDays;
    this.earnedPoints = earnedPoints;
    this.message = message;
  }
}

export interface CheckinSubmitRequest {
  subjects?: string[];
  duration?: string;
  note?: string;
  tags?: string[];
}
