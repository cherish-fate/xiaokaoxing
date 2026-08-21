import { apiService, ApiResponse, ExamItem, ExamListResponse, CreateExamRequest, UpdateExamRequest } from '../api/ApiService';
import { ExamModel } from '../model/ExamModel';
import { ResultUtil, AsyncResult } from '../utils/ResultUtil';
import { Logger } from '../utils/Logger';
import { DateUtil } from '../utils/DateUtil';

const TAG = 'ExamRepository';

export interface ExamListResult {
  list: ExamModel[];
  total: number;
}

export class ExamRepository {
  async fetchExams(limit: number = 3, status: string = ''): Promise<AsyncResult<ExamListResult>> {
    const res: ApiResponse<ExamListResponse> = await apiService.fetchExams(limit, status);
    if (res.code === 401) {
      return ResultUtil.fail<ExamListResult>(401, res.message || '登录已过期');
    }
    if (res.code !== 200 || !res.data) {
      return ResultUtil.fail<ExamListResult>(res.code, res.message || '获取考试失败');
    }
    const list = (res.data.list || []).map((item: ExamItem) => ExamRepository.toModel(item));
    const total = res.data.total || list.length;
    const result: ExamListResult = { list: list, total: total };
    return ResultUtil.success(result);
  }

  async createExam(req: CreateExamRequest): Promise<AsyncResult<ExamModel>> {
    const res = await apiService.createExam(req);
    if (res.code === 401) {
      return ResultUtil.fail<ExamModel>(401, res.message || '登录已过期');
    }
    if ((res.code === 200 || res.code === 201) && res.data) {
      return ResultUtil.success(ExamRepository.toModel(res.data));
    }
    return ResultUtil.fail<ExamModel>(res.code, res.message || '添加考试失败');
  }

  async updateExam(id: number, req: UpdateExamRequest): Promise<AsyncResult<ExamModel>> {
    const res = await apiService.updateExam(id, req);
    if (res.code === 401) {
      return ResultUtil.fail<ExamModel>(401, res.message || '登录已过期');
    }
    if (res.code === 200 && res.data) {
      return ResultUtil.success(ExamRepository.toModel(res.data));
    }
    return ResultUtil.fail<ExamModel>(res.code, res.message || '更新考试失败');
  }

  async deleteExam(id: number): Promise<AsyncResult<null>> {
    const res = await apiService.deleteExam(id);
    if (res.code === 401) {
      return ResultUtil.fail<null>(401, res.message || '登录已过期');
    }
    if (res.code === 200) {
      return ResultUtil.success(null);
    }
    return ResultUtil.fail<null>(res.code, res.message || '删除考试失败');
  }

  static toModel(item: ExamItem): ExamModel {
    const days = typeof item.days_remaining === 'number'
      ? item.days_remaining
      : DateUtil.diffDays(item.exam_date);
    const text = item.days_text || DateUtil.countdownText(days);
    return new ExamModel(
      item.id,
      item.name,
      item.exam_date,
      item.start_time,
      item.end_time,
      item.location || '',
      item.is_completed,
      days,
      text,
      item.status || ''
    );
  }
}

export const examRepository: ExamRepository = new ExamRepository();
Logger.info(TAG, 'ExamRepository initialized');
