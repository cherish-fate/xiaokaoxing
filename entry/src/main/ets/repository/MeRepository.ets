import {
  apiService,
  ApiResponse,
  UserMeInfo,
  UserStatsAggregate,
  AboutInfoResponse,
  NotificationSettingsResponse,
  UpdateNotificationSettingsRequest,
  UpdateUserMeRequest
} from '../api/ApiService';
import {
  MePageModel,
  MeUserProfileModel,
  MeCheckinStatsModel,
  MeLearningStatsModel,
  MeContentCountsModel,
  MeNotificationSettingsModel,
  MeAboutInfoModel
} from '../model/MeModel';
import { ResultUtil, AsyncResult } from '../utils/ResultUtil';
import { Logger } from '../utils/Logger';
import { StorageUtil } from '../utils/StorageUtil';

const TAG = 'MeRepository';

export class MeRepository {
  async loadMePage(): Promise<AsyncResult<MePageModel>> {
    try {
      const results: Array<ApiResponse<UserMeInfo | UserStatsAggregate | AboutInfoResponse>> =
        await Promise.all([
          apiService.fetchUserMe(),
          apiService.fetchUserStats(),
          apiService.fetchAboutInfo()
        ]);

      const userRes: ApiResponse<UserMeInfo> = results[0] as ApiResponse<UserMeInfo>;
      const statsRes: ApiResponse<UserStatsAggregate> = results[1] as ApiResponse<UserStatsAggregate>;
      const aboutRes: ApiResponse<AboutInfoResponse> = results[2] as ApiResponse<AboutInfoResponse>;

      if (userRes.code === 401) {
        return ResultUtil.fail<MePageModel>(401, userRes.message || '登录已过期');
      }

      if (userRes.code !== 200 || !userRes.data) {
        return ResultUtil.fail<MePageModel>(userRes.code, userRes.message || '用户信息加载失败');
      }

      const userData: UserMeInfo = userRes.data;
      const user: MeUserProfileModel = new MeUserProfileModel(
        userData.id,
        userData.nickname || '同学',
        userData.school_name || '',
        userData.major_id || 0,
        userData.major_name || '',
        userData.avatar_url,
        userData.created_at || ''
      );

      let checkin: MeCheckinStatsModel = MeCheckinStatsModel.empty();
      let learning: MeLearningStatsModel = MeLearningStatsModel.empty();
      let contentCounts: MeContentCountsModel = MeContentCountsModel.empty();

      if (statsRes.code === 200 && statsRes.data) {
        const stats: UserStatsAggregate = statsRes.data;
        if (stats.checkin) {
          checkin = new MeCheckinStatsModel(
            stats.checkin.continuous_days || 0,
            stats.checkin.total_days || 0,
            stats.checkin.rank || 0
          );
        }
        if (stats.learning) {
          learning = new MeLearningStatsModel(
            stats.learning.notes_count || 0,
            stats.learning.bookmarks_count || 0,
            stats.learning.documents_count || 0,
            stats.learning.current_gpa || 0,
            stats.learning.daily_question_count || 0,
            stats.learning.exam_subjects_count || 0
          );
        }
        if (stats.my_content) {
          contentCounts = new MeContentCountsModel(
            stats.my_content.uploads_count || 0,
            stats.my_content.votes_count || 0,
            stats.my_content.submissions_count || 0,
            stats.my_content.teams_count || 0
          );
        }
      }

      let about: MeAboutInfoModel = MeAboutInfoModel.empty();
      if (aboutRes.code === 200 && aboutRes.data) {
        const aboutData: AboutInfoResponse = aboutRes.data;
        about = new MeAboutInfoModel(
          aboutData.version || 'v1.0.0',
          aboutData.app_name || '校考星',
          aboutData.description || '',
          aboutData.team,
          aboutData.website,
          aboutData.support_email,
          aboutData.privacy_url,
          aboutData.terms_url,
          aboutData.copyright
        );
      }

      const notificationSettings: MeNotificationSettingsModel = MeNotificationSettingsModel.empty();

      const model: MePageModel = new MePageModel(
        user, checkin, learning, contentCounts, notificationSettings, about
      );
      Logger.info(TAG, '我的页聚合数据加载成功');
      return ResultUtil.success(model);
    } catch (e) {
      Logger.error(TAG, 'loadMePage failed', e as Error);
      return ResultUtil.fail<MePageModel>(500, '网络异常，请检查网络连接');
    }
  }

  async loadNotificationSettings(): Promise<AsyncResult<MeNotificationSettingsModel>> {
    try {
      const res: ApiResponse<NotificationSettingsResponse> = await apiService.fetchNotificationSettings();
      if (res.code === 401) {
        return ResultUtil.fail<MeNotificationSettingsModel>(401, res.message || '登录已过期');
      }
      if (res.code === 200 && res.data) {
        return ResultUtil.success(new MeNotificationSettingsModel(
          !!res.data.exam_reminder,
          !!res.data.checkin_reminder
        ));
      }
      Logger.warn(TAG, `loadNotificationSettings 返回 ${res.code}: ${res.message}`);
      return ResultUtil.fail<MeNotificationSettingsModel>(res.code, res.message || '通知设置加载失败');
    } catch (e) {
      Logger.error(TAG, 'loadNotificationSettings failed', e as Error);
      return ResultUtil.fail<MeNotificationSettingsModel>(-1, '网络异常，通知设置加载失败');
    }
  }

  async updateNotificationSettings(
    req: UpdateNotificationSettingsRequest
  ): Promise<AsyncResult<MeNotificationSettingsModel>> {
    try {
      const res: ApiResponse<NotificationSettingsResponse> =
        await apiService.updateNotificationSettings(req);
      if (res.code === 401) {
        return ResultUtil.fail<MeNotificationSettingsModel>(401, res.message || '登录已过期');
      }
      if (res.code === 200 && res.data) {
        return ResultUtil.success<MeNotificationSettingsModel>(
          new MeNotificationSettingsModel(
            !!res.data.exam_reminder,
            !!res.data.checkin_reminder
          ),
          res.message || '保存成功'
        );
      }
      Logger.warn(TAG, `updateNotificationSettings 返回 ${res.code}: ${res.message}`);
      return ResultUtil.fail<MeNotificationSettingsModel>(res.code, res.message || '保存失败');
    } catch (e) {
      Logger.error(TAG, 'updateNotificationSettings failed', e as Error);
      return ResultUtil.fail<MeNotificationSettingsModel>(-1, '网络异常，保存失败');
    }
  }

  async doLogout(): Promise<AsyncResult<null>> {
    try {
      const res: ApiResponse<null> = await apiService.logout();
      await StorageUtil.clearToken();
      if (res.code === 200) {
        Logger.info(TAG, '退出登录成功');
        return ResultUtil.success(null, res.message || '退出登录成功');
      }
      Logger.warn(TAG, `退出登录接口返回 ${res.code}: ${res.message}`);
      return ResultUtil.success(null, '退出登录成功');
    } catch (e) {
      Logger.error(TAG, 'doLogout failed', e as Error);
      await StorageUtil.clearToken();
      return ResultUtil.success(null, '退出登录成功');
    }
  }

  async loadUserProfile(): Promise<AsyncResult<MeUserProfileModel>> {
    try {
      const res: ApiResponse<UserMeInfo> = await apiService.fetchUserMe();
      if (res.code === 200 && res.data) {
        const info: UserMeInfo = res.data;
        return ResultUtil.success<MeUserProfileModel>(MeUserProfileModel.fromApi(info));
      }
      if (res.code === 401) {
        return ResultUtil.fail<MeUserProfileModel>(401, '请先登录');
      }
      Logger.warn(TAG, `loadUserProfile 返回 ${res.code}: ${res.message}`);
      return ResultUtil.fail<MeUserProfileModel>(res.code, res.message || '用户信息加载失败');
    } catch (e) {
      Logger.error(TAG, 'loadUserProfile failed', e as Error);
      return ResultUtil.fail<MeUserProfileModel>(-1, '网络异常，用户信息加载失败');
    }
  }

  async updateProfile(req: UpdateUserMeRequest): Promise<AsyncResult<MeUserProfileModel>> {
    try {
      const res: ApiResponse<UserMeInfo> = await apiService.updateUserMe(req);
      if (res.code === 200 && res.data) {
        const info: UserMeInfo = res.data;
        return ResultUtil.success<MeUserProfileModel>(
          MeUserProfileModel.fromApi(info),
          res.message || '保存成功'
        );
      }
      if (res.code === 401) {
        return ResultUtil.fail<MeUserProfileModel>(401, '请先登录');
      }
      Logger.warn(TAG, `updateProfile 返回 ${res.code}: ${res.message}`);
      return ResultUtil.fail<MeUserProfileModel>(res.code, res.message || '保存失败');
    } catch (e) {
      Logger.error(TAG, 'updateProfile failed', e as Error);
      return ResultUtil.fail<MeUserProfileModel>(-1, '网络异常，保存失败');
    }
  }

  async loadAboutInfo(): Promise<AsyncResult<MeAboutInfoModel>> {
    try {
      const res: ApiResponse<AboutInfoResponse> = await apiService.fetchAboutInfo();
      let about: MeAboutInfoModel = MeAboutInfoModel.empty();
      if (res.code === 200 && res.data) {
        const aboutData: AboutInfoResponse = res.data;
        about = new MeAboutInfoModel(
          aboutData.version || 'v1.0.0',
          aboutData.app_name || '校考星',
          aboutData.description || '',
          aboutData.team,
          aboutData.website,
          aboutData.support_email,
          aboutData.privacy_url,
          aboutData.terms_url,
          aboutData.copyright
        );
      }
      return ResultUtil.success(about, res.message || '加载成功');
    } catch (e) {
      Logger.error(TAG, 'loadAboutInfo failed', e as Error);
      // 关于页失败不阻断，返回默认值
      return ResultUtil.success(MeAboutInfoModel.empty(), '加载成功');
    }
  }
}

export const meRepository: MeRepository = new MeRepository();
