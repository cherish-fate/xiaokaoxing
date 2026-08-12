import {
  apiService,
  ApiResponse,
  TeamListResponse,
  TeamItem,
  TeamDetailResponse,
  TeamMember,
  CreateTeamRequest,
  CreateTeamResponse,
  JoinResponse,
  ApplicationsResponse,
  JoinApplication,
  ApplicationProcessResponse
} from '../api/ApiService';
import {
  TeamListModel,
  TeamItemModel,
  TeamDetailModel,
  TeamMemberModel,
  CreateTeamArgs,
  CreateTeamResultModel,
  JoinTeamResultModel,
  ApplicationsModel,
  JoinApplicationModel,
  ProcessApplicationResultModel
} from '../model/TeamModel';
import { ResultUtil, AsyncResult } from '../utils/ResultUtil';
import { Logger } from '../utils/Logger';
import { DateUtil } from '../utils/DateUtil';

const TAG = 'TeamRepository';

export class TeamRepository {
  private mapTeamItem(t: TeamItem): TeamItemModel {
    return new TeamItemModel(
      t.id,
      t.name || '',
      t.subject || '',
      t.member_count || 0,
      t.max_members || 30,
      t.checkin_rate || 0,
      t.total_checkins || 0,
      t.online_count || 0,
      !!t.is_creator,
      t.join_status || null,
      t.pending_requests || 0,
      t.description || null,
      t.resource_count || 0
    );
  }

  private mapTeamMember(m: TeamMember): TeamMemberModel {
    return new TeamMemberModel(
      m.user_id || 0,
      m.nickname || '',
      m.avatar_url || null,
      m.role || '',
      m.joined_at ? DateUtil.toShortDateTime(m.joined_at) : ''
    );
  }

  private mapJoinApplication(a: JoinApplication): JoinApplicationModel {
    return new JoinApplicationModel(
      a.application_id,
      a.user_id || 0,
      a.nickname || '',
      a.avatar_url || null,
      a.applied_at ? DateUtil.toShortDateTime(a.applied_at) : ''
    );
  }

  async loadTeams(subject?: string): Promise<AsyncResult<TeamListModel>> {
    const res: ApiResponse<TeamListResponse> = await apiService.fetchTeams(subject);
    if (res.code === 401) {
      return ResultUtil.fail<TeamListModel>(401, res.message || '登录已过期');
    }
    if (res.code !== 200 || !res.data) {
      return ResultUtil.fail<TeamListModel>(res.code, res.message || '小队列表加载失败');
    }
    const myTeams = (res.data.my_teams || []).map(t => this.mapTeamItem(t));
    const recommendedTeams = (res.data.recommended_teams || []).map(t => this.mapTeamItem(t));
    return ResultUtil.success(new TeamListModel(myTeams, recommendedTeams));
  }

  async createTeam(req: CreateTeamArgs): Promise<AsyncResult<CreateTeamResultModel>> {
    if (!req.name || req.name.trim().length === 0) {
      return ResultUtil.fail<CreateTeamResultModel>(400, '小队名称不能为空');
    }
    if (req.name.length > 20) {
      return ResultUtil.fail<CreateTeamResultModel>(400, '小队名称不能超过20字');
    }
    if (!req.subject) {
      return ResultUtil.fail<CreateTeamResultModel>(400, '请选择关联科目');
    }
    const body: CreateTeamRequest = {
      name: req.name.trim(),
      subject: req.subject,
      description: req.description && req.description.length > 100
        ? req.description.substring(0, 100) : req.description,
      need_approval: req.needApproval !== false
    };
    const res: ApiResponse<CreateTeamResponse> = await apiService.createTeam(body);
    if (res.code === 401) {
      return ResultUtil.fail<CreateTeamResultModel>(401, res.message || '登录已过期');
    }
    if ((res.code !== 200 && res.code !== 201) || !res.data) {
      return ResultUtil.fail<CreateTeamResultModel>(
        res.code, res.message || '创建小队失败'
      );
    }
    const result = new CreateTeamResultModel(
      res.data.id,
      res.data.name,
      res.data.subject,
      res.data.description,
      res.data.member_count || 1,
      res.data.max_members || 30,
      !!res.data.need_approval,
      res.data.created_at ? DateUtil.toShortDateTime(res.data.created_at) : ''
    );
    Logger.info(TAG, `小队创建成功: ${result.id}`);
    return ResultUtil.success(result);
  }

  async loadTeamDetail(id: number): Promise<AsyncResult<TeamDetailModel>> {
    const res: ApiResponse<TeamDetailResponse> = await apiService.fetchTeamDetail(id);
    if (res.code === 401) {
      return ResultUtil.fail<TeamDetailModel>(401, res.message || '登录已过期');
    }
    if (res.code === 404) {
      return ResultUtil.fail<TeamDetailModel>(404, res.message || '小队不存在');
    }
    if (res.code !== 200 || !res.data) {
      return ResultUtil.fail<TeamDetailModel>(res.code, res.message || '小队详情加载失败');
    }
    const members = (res.data.members || []).map(m => this.mapTeamMember(m));
    const model = new TeamDetailModel(
      res.data.id,
      res.data.name || '',
      res.data.subject || '',
      res.data.description,
      res.data.creator_id || 0,
      res.data.member_count || 0,
      res.data.max_members || 30,
      res.data.checkin_rate || 0,
      res.data.total_checkins || 0,
      !!res.data.need_approval,
      !!res.data.is_creator,
      !!res.data.is_member,
      members
    );
    return ResultUtil.success(model);
  }

  async joinTeam(id: number): Promise<AsyncResult<JoinTeamResultModel>> {
    const res: ApiResponse<JoinResponse> = await apiService.joinTeam(id);
    if (res.code === 401) {
      return ResultUtil.fail<JoinTeamResultModel>(401, res.message || '登录已过期');
    }
    if (res.code === 409) {
      return ResultUtil.fail<JoinTeamResultModel>(409, res.message || '您已申请加入该小队');
    }
    if (res.code === 400) {
      return ResultUtil.fail<JoinTeamResultModel>(400, res.message || '小队已满员');
    }
    if ((res.code !== 200 && res.code !== 201) || !res.data) {
      return ResultUtil.fail<JoinTeamResultModel>(res.code, res.message || '加入小队失败');
    }
    return ResultUtil.success(new JoinTeamResultModel(
      res.data.team_id,
      res.data.status || '',
      res.message || '',
      res.data.applied_at ? DateUtil.toShortDateTime(res.data.applied_at) : ''
    ));
  }

  async loadApplications(id: number): Promise<AsyncResult<ApplicationsModel>> {
    const res: ApiResponse<ApplicationsResponse> = await apiService.fetchApplications(id);
    if (res.code === 401) {
      return ResultUtil.fail<ApplicationsModel>(401, res.message || '登录已过期');
    }
    if (res.code === 403) {
      return ResultUtil.fail<ApplicationsModel>(403, res.message || '仅队长可查看申请列表');
    }
    if (res.code !== 200 || !res.data) {
      return ResultUtil.fail<ApplicationsModel>(res.code, res.message || '申请列表加载失败');
    }
    const pending = (res.data.pending || []).map(a => this.mapJoinApplication(a));
    return ResultUtil.success(new ApplicationsModel(pending, res.data.total || pending.length));
  }

  async approveApplication(teamId: number, applicationId: number): Promise<AsyncResult<ProcessApplicationResultModel>> {
    const res: ApiResponse<ApplicationProcessResponse> =
      await apiService.processApplication(teamId, applicationId, 'approve');
    if (res.code === 401) {
      return ResultUtil.fail<ProcessApplicationResultModel>(401, res.message || '登录已过期');
    }
    if (res.code === 403) {
      return ResultUtil.fail<ProcessApplicationResultModel>(403, res.message || '仅队长可处理申请');
    }
    if (res.code !== 200 || !res.data) {
      return ResultUtil.fail<ProcessApplicationResultModel>(res.code, res.message || '审核失败');
    }
    return ResultUtil.success(new ProcessApplicationResultModel(
      res.data.application_id,
      res.data.status,
      res.message || '审核通过'
    ));
  }

  async rejectApplication(teamId: number, applicationId: number): Promise<AsyncResult<ProcessApplicationResultModel>> {
    const res: ApiResponse<ApplicationProcessResponse> =
      await apiService.processApplication(teamId, applicationId, 'reject');
    if (res.code === 401) {
      return ResultUtil.fail<ProcessApplicationResultModel>(401, res.message || '登录已过期');
    }
    if (res.code === 403) {
      return ResultUtil.fail<ProcessApplicationResultModel>(403, res.message || '仅队长可处理申请');
    }
    if (res.code !== 200 || !res.data) {
      return ResultUtil.fail<ProcessApplicationResultModel>(res.code, res.message || '拒绝失败');
    }
    return ResultUtil.success(new ProcessApplicationResultModel(
      res.data.application_id,
      res.data.status,
      res.message || '已拒绝申请'
    ));
  }

  async leaveTeam(id: number): Promise<AsyncResult<null>> {
    const res: ApiResponse<null> = await apiService.leaveTeam(id);
    if (res.code === 401) {
      return ResultUtil.fail<null>(401, res.message || '登录已过期');
    }
    if (res.code === 403) {
      return ResultUtil.fail<null>(403, res.message || '队长不能直接退出，请先解散小队');
    }
    if (res.code !== 200) {
      return ResultUtil.fail<null>(res.code, res.message || '退出小队失败');
    }
    return ResultUtil.success(null);
  }

  async disbandTeam(id: number): Promise<AsyncResult<null>> {
    const res: ApiResponse<null> = await apiService.disbandTeam(id);
    if (res.code === 401) {
      return ResultUtil.fail<null>(401, res.message || '登录已过期');
    }
    if (res.code === 403) {
      return ResultUtil.fail<null>(403, res.message || '仅队长可解散小队');
    }
    if (res.code !== 200) {
      return ResultUtil.fail<null>(res.code, res.message || '解散小队失败');
    }
    return ResultUtil.success(null);
  }
}

export const teamRepository: TeamRepository = new TeamRepository();
