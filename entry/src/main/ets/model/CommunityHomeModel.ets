import { CheckinStatsModel } from './CheckinModel';
import { HotVoteModel } from './VoteModel';
import { HotTeamModel } from './TeamModel';
import { CommunityResourceModel } from './SharedResourceModel';

// 重新导出，方便外部统一引用
export { CheckinStatsModel, HotVoteModel, HotTeamModel, CommunityResourceModel };

export class CommunityHomePageModel {
  checkinStats: CheckinStatsModel;
  hotVotes: HotVoteModel[];
  hotTeams: HotTeamModel[];
  latestResources: CommunityResourceModel[];

  constructor(
    checkinStats: CheckinStatsModel,
    hotVotes: HotVoteModel[],
    hotTeams: HotTeamModel[],
    latestResources: CommunityResourceModel[]
  ) {
    this.checkinStats = checkinStats;
    this.hotVotes = hotVotes;
    this.hotTeams = hotTeams;
    this.latestResources = latestResources;
  }

  static empty(): CommunityHomePageModel {
    return new CommunityHomePageModel(
      new CheckinStatsModel(0, 0, 0),
      [],
      [],
      []
    );
  }
}

// 兼容旧命名
export { CommunityHomePageModel as CommunityHomeModel };
