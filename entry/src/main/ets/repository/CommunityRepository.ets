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
  private mapCheckinStats(s: CheckinStats): CheckinStatsModel {
    return new CheckinStatsModel(
      s.total_days || 0,
      s.continuous_days || 0,
      s.rank || 0
    );
  }

  private mapHotVote(v: HotVote): HotVoteModel {
    return new HotVoteModel(
      v.id,
      v.subject || '',
      v.title || '',
      v.vote_count || 0,
      v.confidence || 0,
      v.stars || 0
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
    const stats: CheckinStatsModel = this.mapCheckinStats(
      res.data.checkin_stats || { total_days: 0, continuous_days: 0, rank: 0 }
    );
    const hotVotes: HotVoteModel[] = (res.data.hot_votes || []).map(v => this.mapHotVote(v));
    const hotTeams: HotTeamModel[] = (res.data.hot_teams || []).map(t => this.mapHotTeam(t));
    const latestResources: CommunityResourceModel[] = (res.data.latest_resources || [])
      .map(r => this.mapCommunityResource(r));

    const model = new CommunityHomePageModel(stats, hotVotes, hotTeams, latestResources);
    Logger.info(TAG, '社区主页数据加载成功');
    return ResultUtil.success(model);
  }
}

export const communityRepository: CommunityRepository = new CommunityRepository();
