export class HotTeamModel {
  id: number;
  name: string;
  subject: string;
  memberCount: number;
  maxMembers: number;
  checkinRate: number;
  totalCheckins: number;
  onlineCount: number;
  isCreator: boolean;
  joinStatus: string | null;
  pendingRequests: number;
  description: string | null;
  resourceCount: number;

  constructor(
    id: number,
    name: string,
    subject: string,
    memberCount: number,
    maxMembers: number,
    checkinRate: number,
    totalCheckins: number,
    onlineCount: number,
    isCreator: boolean,
    joinStatus: string | null,
    pendingRequests: number = 0,
    description: string | null = null,
    resourceCount: number = 0
  ) {
    this.id = id;
    this.name = name;
    this.subject = subject;
    this.memberCount = memberCount;
    this.maxMembers = maxMembers;
    this.checkinRate = checkinRate;
    this.totalCheckins = totalCheckins;
    this.onlineCount = onlineCount;
    this.isCreator = isCreator;
    this.joinStatus = joinStatus;
    this.pendingRequests = pendingRequests;
    this.description = description;
    this.resourceCount = resourceCount;
  }

  rateText(): string {
    return `${this.checkinRate.toFixed(0)}%`;
  }

  subjectIconBg(): string {
    return '#E8F0FF';
  }

  subjectIconEmoji(): string {
    if (this.subject.indexOf('高数') >= 0 || this.subject.indexOf('数学') >= 0) return '📐';
    if (this.subject.indexOf('英语') >= 0) return '📚';
    if (this.subject.indexOf('线代') >= 0) return '📊';
    if (this.subject.indexOf('物理') >= 0) return '⚛️';
    if (this.subject.indexOf('计科') >= 0 || this.subject.indexOf('计算机') >= 0 || this.subject.indexOf('数据') >= 0) return '💻';
    return '🎓';
  }

  subjectIconColor(): string {
    return '#4A7FFF';
  }

  // 计算属性：是否已经是成员（isCreator 或 joinStatus === 已通过）
  get isMember(): boolean {
    return this.isCreator || this.joinStatus === '已通过';
  }
}

// 兼容 TeamItemModel
export { HotTeamModel as TeamItemModel };

export class TeamListModel {
  myTeams: HotTeamModel[];
  recommendedTeams: HotTeamModel[];

  constructor(myTeams: HotTeamModel[], recommendedTeams: HotTeamModel[]) {
    this.myTeams = myTeams;
    this.recommendedTeams = recommendedTeams;
  }

  static empty(): TeamListModel {
    return new TeamListModel([], []);
  }
}

export class TeamMemberModel {
  userId: number;
  nickname: string;
  avatarUrl: string | null;
  role: string;
  joinedAt: string;

  constructor(
    userId: number,
    nickname: string,
    avatarUrl: string | null,
    role: string,
    joinedAt: string
  ) {
    this.userId = userId;
    this.nickname = nickname;
    this.avatarUrl = avatarUrl;
    this.role = role;
    this.joinedAt = joinedAt;
  }

  isLeader(): boolean {
    return this.role === '队长';
  }
}

export class TeamDetailModel {
  id: number;
  name: string;
  subject: string;
  description: string | null;
  creatorId: number;
  memberCount: number;
  maxMembers: number;
  checkinRate: number;
  totalCheckins: number;
  needApproval: boolean;
  isCreator: boolean;
  isMember: boolean;
  members: TeamMemberModel[];

  constructor(
    id: number,
    name: string,
    subject: string,
    description: string | null,
    creatorId: number,
    memberCount: number,
    maxMembers: number,
    checkinRate: number,
    totalCheckins: number,
    needApproval: boolean,
    isCreator: boolean,
    isMember: boolean,
    members: TeamMemberModel[]
  ) {
    this.id = id;
    this.name = name;
    this.subject = subject;
    this.description = description;
    this.creatorId = creatorId;
    this.memberCount = memberCount;
    this.maxMembers = maxMembers;
    this.checkinRate = checkinRate;
    this.totalCheckins = totalCheckins;
    this.needApproval = needApproval;
    this.isCreator = isCreator;
    this.isMember = isMember;
    this.members = members;
  }

  rateText(): string {
    return `${this.checkinRate.toFixed(0)}%`;
  }

  static empty(): TeamDetailModel {
    return new TeamDetailModel(0, '', '', null, 0, 0, 30, 0, 0, true, false, false, []);
  }
}

export class JoinApplicationModel {
  applicationId: number;
  userId: number;
  nickname: string;
  avatarUrl: string | null;
  appliedAt: string;

  constructor(
    applicationId: number,
    userId: number,
    nickname: string,
    avatarUrl: string | null,
    appliedAt: string
  ) {
    this.applicationId = applicationId;
    this.userId = userId;
    this.nickname = nickname;
    this.avatarUrl = avatarUrl;
    this.appliedAt = appliedAt;
  }
}

export class ApplicationsModel {
  pending: JoinApplicationModel[];
  total: number;

  constructor(pending: JoinApplicationModel[], total: number) {
    this.pending = pending;
    this.total = total;
  }

  static empty(): ApplicationsModel {
    return new ApplicationsModel([], 0);
  }
}

export { ApplicationsModel as TeamApplicationsModel };

export interface CreateTeamRequest {
  name: string;
  subject: string;
  description?: string;
  need_approval?: boolean;
}

// 页面/Repository调用端专用：驼峰命名版本
export interface CreateTeamArgs {
  name: string;
  subject: string;
  description?: string;
  needApproval?: boolean;
}

export class CreateTeamResultModel {
  id: number;
  name: string;
  subject: string;
  description: string | null;
  memberCount: number;
  maxMembers: number;
  needApproval: boolean;
  createdAt: string;

  constructor(
    id: number,
    name: string,
    subject: string,
    description: string | null,
    memberCount: number,
    maxMembers: number,
    needApproval: boolean,
    createdAt: string
  ) {
    this.id = id;
    this.name = name;
    this.subject = subject;
    this.description = description;
    this.memberCount = memberCount;
    this.maxMembers = maxMembers;
    this.needApproval = needApproval;
    this.createdAt = createdAt;
  }
}

export class JoinTeamResultModel {
  teamId: number;
  status: string;
  message: string;
  appliedAt: string;

  constructor(teamId: number, status: string, message: string = '', appliedAt: string = '') {
    this.teamId = teamId;
    this.status = status;
    this.message = message;
    this.appliedAt = appliedAt;
  }
}

export { JoinTeamResultModel as JoinResultModel };

export class ProcessApplicationResultModel {
  applicationId: number;
  status: string;
  message: string;

  constructor(applicationId: number, status: string, message: string = '') {
    this.applicationId = applicationId;
    this.status = status;
    this.message = message;
  }
}

export { ProcessApplicationResultModel as ApplicationProcessResultModel };
