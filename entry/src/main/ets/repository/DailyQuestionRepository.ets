import {
  apiService,
  ApiResponse,
  DailyQuestionToday,
  SubmitDailyAnswerRequest,
  SubmitDailyAnswerData
} from '../api/ApiService';
import {
  DailyQuestionModel,
  DailyQuestionResultModel
} from '../model/DailyQuestionModel';
import { ResultUtil, AsyncResult } from '../utils/ResultUtil';
import { Logger } from '../utils/Logger';

const TAG: string = 'DailyQuestionRepository';

export class DailyQuestionRepository {
  async loadTodayQuestion(): Promise<AsyncResult<DailyQuestionModel>> {
    const res: ApiResponse<DailyQuestionToday> = await apiService.fetchDailyQuestionToday();
    if (res.code === 401) {
      return ResultUtil.fail<DailyQuestionModel>(401, res.message || '登录已过期');
    }
    if (res.code !== 200 || !res.data) {
      return ResultUtil.fail<DailyQuestionModel>(res.code, res.message || '获取题目失败');
    }
    try {
      const model: DailyQuestionModel = DailyQuestionModel.fromApi(res.data);
      Logger.info(TAG, '今日题目加载成功');
      return ResultUtil.success(model);
    } catch (e) {
      Logger.error(TAG, '题目数据转换失败', e as Error);
      return ResultUtil.fail<DailyQuestionModel>(500, '数据解析失败');
    }
  }

  async submitAnswer(
    questionId: number,
    selected: string
  ): Promise<AsyncResult<DailyQuestionResultModel>> {
    const req: SubmitDailyAnswerRequest = {
      question_id: questionId,
      selected: selected
    };
    const res: ApiResponse<SubmitDailyAnswerData> = await apiService.submitDailyAnswer(req);
    if (res.code === 401) {
      return ResultUtil.fail<DailyQuestionResultModel>(401, res.message || '登录已过期');
    }
    if (res.code === 409) {
      return ResultUtil.fail<DailyQuestionResultModel>(409, res.message || '今日已答题');
    }
    if (res.code !== 200 || !res.data) {
      return ResultUtil.fail<DailyQuestionResultModel>(res.code, res.message || '提交失败');
    }
    try {
      const model: DailyQuestionResultModel = DailyQuestionResultModel.fromApi(res.data);
      Logger.info(TAG, '答案提交成功');
      return ResultUtil.success(model);
    } catch (e) {
      Logger.error(TAG, '结果数据转换失败', e as Error);
      return ResultUtil.fail<DailyQuestionResultModel>(500, '数据解析失败');
    }
  }
}

export const dailyQuestionRepository: DailyQuestionRepository = new DailyQuestionRepository();
