import { apiService, ApiResponse, HomeAggregate, TaskItem, UpdateTaskRequest } from '../api/ApiService';
import { HomeModel } from '../model/HomeModel';
import { UserModel, GreetingModel } from '../model/UserModel';
import { ExamModel, ExamCountdownModel, TodayProgressModel } from '../model/ExamModel';
import { TaskModel, TodayTaskListModel } from '../model/TaskModel';
import { ResourceModel } from '../model/ResourceModel';
import { ResultUtil, AsyncResult } from '../utils/ResultUtil';
import { DateUtil } from '../utils/DateUtil';
import { Logger } from '../utils/Logger';
import { examRepository } from './ExamRepository';

const TAG = 'HomeRepository';

export class HomeRepository {
  async loadHomeData(): Promise<AsyncResult<HomeModel>> {
    const res: ApiResponse<HomeAggregate> = await apiService.fetchHome();
    if (res.code === 401) {
      return ResultUtil.fail<HomeModel>(401, res.message || '登录已过期');
    }
    if (res.code !== 200 || !res.data) {
      return ResultUtil.fail<HomeModel>(res.code, res.message || '首页数据加载失败');
    }
    const data: HomeAggregate = res.data;

    const user = new UserModel(
      data.user.id,
      data.user.nickname || '',
      data.user.avatar_url || ''
    );
    const greeting = new GreetingModel(user);

    const cd = data.exam_countdown;
    const countdown = new ExamCountdownModel(
      cd.has_exam,
      cd.exam_name || '',
      cd.exam_date || '',
      cd.start_time || '',
      cd.end_time || '',
      cd.countdown_days || 0,
      cd.countdown_text || ''
    );

    const tp = data.today_progress;
    const progress = new TodayProgressModel(tp.completed || 0, tp.total || 0, tp.progress_percentage || 0);

    const recentExams: ExamModel[] = (data.recent_exams || []).map(item => new ExamModel(
      item.id,
      item.name,
      item.exam_date,
      item.start_time,
      item.end_time,
      item.location || '',
      false,
      item.days_remaining,
      item.days_text,
      item.days_remaining < 0 ? 'expired' : (item.days_remaining === 0 ? 'today' : 'upcoming')
    ));

    // 额外请求完整考试列表替换首页的3条限制
    let allExams: ExamModel[] = recentExams;
    const examResult = await examRepository.fetchExams(50, '');
    if (examResult.success && examResult.data) {
      allExams = examResult.data;
    }

    const taskList: TaskModel[] = (data.today_tasks || []).map(item =>
      new TaskModel(item.id, item.task_name, item.plan_date, item.is_completed)
    );
    const completedCount = taskList.filter(t => t.isCompleted).length;
    const tasks = new TodayTaskListModel(
      taskList.length > 0,
      taskList.length,
      completedCount,
      taskList,
      '今日暂无任务，去备考页添加学习计划吧'
    );

    const resources: ResourceModel[] = (data.recommended_resources || []).map(item =>
      new ResourceModel(item.id, item.title, item.type_tag, item.description, item.file_url || '')
    );

    const model = new HomeModel(user, greeting, countdown, progress, allExams, tasks, resources);
    Logger.info(TAG, '首页数据加载成功');
    return ResultUtil.success(model);
  }

  async refreshTaskStatus(taskId: number, isCompleted: boolean): Promise<AsyncResult<TaskModel>> {
    const req: UpdateTaskRequest = { is_completed: isCompleted };
    const res = await apiService.updateTask(taskId, req);
    if (res.code === 401) {
      return ResultUtil.fail<TaskModel>(401, res.message || '登录已过期');
    }
    if (res.code === 200 && res.data) {
      return ResultUtil.success(new TaskModel(res.data.id, res.data.task_name, res.data.plan_date, res.data.is_completed));
    }
    return ResultUtil.fail<TaskModel>(res.code, res.message || '更新任务失败');
  }

  async deleteExam(id: number): Promise<AsyncResult<null>> {
    const res = await apiService.deleteExam(id);
    if (res.code === 200) {
      return ResultUtil.success(null);
    }
    return ResultUtil.fail<null>(res.code, res.message || '删除考试失败');
  }
}

export const homeRepository: HomeRepository = new HomeRepository();
