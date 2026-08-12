import {
  apiService,
  ApiResponse,
  TodayCheckinResponse,
  CheckinSubmitRequest,
  CheckinSubmitResponse,
  CalendarResponse,
  RankingResponse,
  RankUser
} from '../api/ApiService';
import {
  TodayCheckinModel,
  CheckinRecordModel,
  CheckinSubmitResultModel,
  CheckinCalendarModel,
  CalendarDayModel,
  RankingModel,
  RankUserModel
} from '../model/CheckinModel';
import { ResultUtil, AsyncResult } from '../utils/ResultUtil';
import { Logger } from '../utils/Logger';

const TAG = 'CheckinRepository';

export class CheckinRepository {
  private mapTodayCheckin(resp: TodayCheckinResponse): TodayCheckinModel {
    const record: CheckinRecordModel | null = resp.checkin_record
      ? new CheckinRecordModel(
          resp.checkin_record.id,
          resp.checkin_record.subjects || [],
          resp.checkin_record.duration || '',
          resp.checkin_record.note || '',
          resp.checkin_record.tags || []
        )
      : null;
    return new TodayCheckinModel(
      !!resp.has_checked_in,
      resp.continuous_days || 0,
      resp.total_days || 0,
      resp.rank || 0,
      record
    );
  }

  private mapRankUser(u: RankUser, isMe: boolean = false): RankUserModel {
    return new RankUserModel(
      u.rank || 0,
      u.user_id || 0,
      u.nickname || '',
      u.avatar_url || null,
      u.continuous_days || 0,
      u.total_days || 0,
      isMe
    );
  }

  async loadTodayStatus(): Promise<AsyncResult<TodayCheckinModel>> {
    const res: ApiResponse<TodayCheckinResponse> = await apiService.fetchTodayCheckinStatus();
    if (res.code === 401) {
      return ResultUtil.fail<TodayCheckinModel>(401, res.message || '登录已过期');
    }
    if (res.code !== 200 || !res.data) {
      return ResultUtil.fail<TodayCheckinModel>(res.code, res.message || '打卡状态加载失败');
    }
    return ResultUtil.success(this.mapTodayCheckin(res.data));
  }

  async submitCheckin(req: CheckinSubmitRequest): Promise<AsyncResult<CheckinSubmitResultModel>> {
    const body: CheckinSubmitRequest = {
      subjects: req.subjects,
      duration: req.duration,
      note: req.note,
      tags: req.tags
    };
    const res: ApiResponse<CheckinSubmitResponse> = await apiService.submitCheckin(body);
    if (res.code === 401) {
      return ResultUtil.fail<CheckinSubmitResultModel>(401, res.message || '登录已过期');
    }
    if (res.code === 409) {
      return ResultUtil.fail<CheckinSubmitResultModel>(409, res.message || '今日已打卡');
    }
    if ((res.code !== 200 && res.code !== 201) || !res.data) {
      return ResultUtil.fail<CheckinSubmitResultModel>(res.code, res.message || '打卡失败');
    }
    const result = new CheckinSubmitResultModel(
      res.data.id,
      res.data.checkin_date || '',
      res.data.continuous_days || 0,
      res.data.total_days || 0,
      res.data.earned_points || 0,
      res.message || '打卡成功'
    );
    Logger.info(TAG, `打卡成功: 连续${result.continuousDays}天`);
    return ResultUtil.success(result);
  }

  async loadCalendar(year?: number, month?: number): Promise<AsyncResult<CheckinCalendarModel>> {
    const res: ApiResponse<CalendarResponse> = await apiService.fetchCheckinCalendar(year, month);
    if (res.code === 401) {
      return ResultUtil.fail<CheckinCalendarModel>(401, res.message || '登录已过期');
    }
    if (res.code !== 200 || !res.data) {
      return ResultUtil.fail<CheckinCalendarModel>(res.code, res.message || '日历加载失败');
    }
    const days: CalendarDayModel[] = (res.data.days || []).map(d => {
      return new CalendarDayModel(
        d.date || '',
        d.day || 0,
        !!d.is_checked,
        !!d.is_today
      );
    });
    const model = new CheckinCalendarModel(res.data.year, res.data.month, days);
    return ResultUtil.success(model);
  }

  async loadRanking(limit: number = 50): Promise<AsyncResult<RankingModel>> {
    const res: ApiResponse<RankingResponse> = await apiService.fetchCheckinRanking(limit);
    if (res.code === 401) {
      return ResultUtil.fail<RankingModel>(401, res.message || '登录已过期');
    }
    if (res.code !== 200 || !res.data) {
      return ResultUtil.fail<RankingModel>(res.code, res.message || '排行榜加载失败');
    }
    const list: RankUserModel[] = (res.data.list || []).map(u => this.mapRankUser(u));
    const myRank: RankUserModel = res.data.my_rank ? this.mapRankUser(res.data.my_rank, true)
      : new RankUserModel(0, 0, '我', null, 0, 0, true);
    return ResultUtil.success(new RankingModel(list, myRank));
  }
}

export const checkinRepository: CheckinRepository = new CheckinRepository();
