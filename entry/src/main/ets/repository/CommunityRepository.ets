import {
  apiService,
  ApiResponse,
  CommunityHomeResponse,
  CheckinStats,
  HotVote,
  HotTeam,
  CommunityResource
} from '../api/ApiService';
import {
  CommunityHomePageModel,
  CheckinStatsModel,
  HotVoteModel,
  HotTeamModel,
  CommunityResourceModel
} from '../model/CommunityHomeModel';
import { ResultUtil, AsyncResult } from '../utils/ResultUtil';
import { Logger } from '../utils/Logger';

const TAG = 'CommunityRepository';

export class CommunityRepository {
  private mapCheckinStats(s: CheckinStats, checkedWeekDays: number[]): CheckinStatsModel {
    return new CheckinStatsModel(
      s.total_days || 0,
      s.continuous_days || 0,
      s.rank || 0,
      checkedWeekDays
    );
  }

  private mapHotVote(v: HotVote, totalUsers: number): HotVoteModel {
    return new HotVoteModel(
      v.id,
      v.subject || '',
      v.title || '',
      v.vote_count || 0,
      v.confidence || 0,
      v.stars || 0,
      totalUsers
    );
  }

  private mapHotTeam(t: HotTeam): HotTeamModel {
    return new HotTeamModel(
      t.id,
      t.name || '',
      t.subject || '',
      t.member_count || 0,
      t.max_members || 30,
      t.checkin_rate || 0,
      t.total_checkins || 0,
      t.online_count || 0,
      !!t.is_creator,
      t.join_status || null
    );
  }

  private mapCommunityResource(r: CommunityResource): CommunityResourceModel {
    return new CommunityResourceModel(
      r.id,
      r.title || '',
      r.author || '',
      r.created_at || '',
      r.status || ''
    );
  }

  async loadCommunityHome(): Promise<AsyncResult<CommunityHomePageModel>> {
    const res: ApiResponse<CommunityHomeResponse> = await apiService.fetchCommunityHome();
    if (res.code === 401) {
      return ResultUtil.fail<CommunityHomePageModel>(401, res.message || '登录已过期');
    }
    if (res.code !== 200 || !res.data) {
      return ResultUtil.fail<CommunityHomePageModel>(
        res.code,
        res.message || '社区主页数据加载失败'
      );
    }
    const topTotalUsers: number = res.data.total_users || 0;
    const topCheckedWeekDays: number[] = res.data.checked_week_days || [];
    const stats: CheckinStatsModel = this.mapCheckinStats(
      res.data.checkin_stats || { total_days: 0, continuous_days: 0, rank: 0 },
      topCheckedWeekDays
    );
    const hotVotes: HotVoteModel[] = (res.data.hot_votes || []).map(v => this.mapHotVote(v, topTotalUsers));
    const hotTeams: HotTeamModel[] = (res.data.hot_teams || []).map(t => this.mapHotTeam(t));
    const latestResources: CommunityResourceModel[] = (res.data.latest_resources || [])
      .map(r => this.mapCommunityResource(r));

    const model = new CommunityHomePageModel(stats, hotVotes, hotTeams, latestResources, topTotalUsers, topCheckedWeekDays);
    Logger.info(TAG, '社区主页数据加载成功');
    return ResultUtil.success(model);
  }
}

export const communityRepository: CommunityRepository = new CommunityRepository();
