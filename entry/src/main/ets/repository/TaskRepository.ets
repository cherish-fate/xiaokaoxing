import { apiService, ApiResponse, TaskItem, TodayTaskResponse, UpdateTaskRequest, CreateTaskRequest } from '../api/ApiService';
import { TaskModel, TodayTaskListModel } from '../model/TaskModel';
import { ResultUtil, AsyncResult } from '../utils/ResultUtil';

export class TaskRepository {
  async createTask(req: CreateTaskRequest): Promise<AsyncResult<TaskModel>> {
    const res = await apiService.createTask(req);
    if (res.code === 401) {
      return ResultUtil.fail<TaskModel>(401, res.message || '登录已过期');
    }
    if ((res.code === 200 || res.code === 201) && res.data) {
      return ResultUtil.success(new TaskModel(res.data.id, res.data.task_name, res.data.plan_date, res.data.is_completed));
    }
    return ResultUtil.fail<TaskModel>(res.code, res.message || '任务添加失败');
  }

  async fetchTodayTasks(): Promise<AsyncResult<TodayTaskListModel>> {
    const res: ApiResponse<TodayTaskResponse> = await apiService.fetchTodayTasks();
    if (res.code === 401) {
      return ResultUtil.fail<TodayTaskListModel>(401, res.message || '登录已过期');
    }
    if (res.code !== 200 || !res.data) {
      return ResultUtil.fail<TodayTaskListModel>(res.code, res.message || '获取今日任务失败');
    }
    const list = (res.data.list || []).map((item: TaskItem) => new TaskModel(item.id, item.task_name, item.plan_date, item.is_completed));
    const model = new TodayTaskListModel(
      res.data.has_tasks,
      res.data.total,
      res.data.completed,
      list,
      res.data.empty_hint || '今日暂无任务，去备考页添加学习计划吧'
    );
    return ResultUtil.success(model);
  }

  async updateTaskStatus(id: number, isCompleted: boolean): Promise<AsyncResult<TaskModel>> {
    const req: UpdateTaskRequest = { is_completed: isCompleted };
    return this.updateTask(id, req);
  }

  async updateTask(id: number, req: UpdateTaskRequest): Promise<AsyncResult<TaskModel>> {
    const res = await apiService.updateTask(id, req);
    if (res.code === 401) {
      return ResultUtil.fail<TaskModel>(401, res.message || '登录已过期');
    }
    if (res.code === 200 && res.data) {
      return ResultUtil.success(new TaskModel(res.data.id, res.data.task_name, res.data.plan_date, res.data.is_completed));
    }
    return ResultUtil.fail<TaskModel>(res.code, res.message || '更新任务失败');
  }

  async deleteTask(id: number): Promise<AsyncResult<null>> {
    const res = await apiService.deleteTask(id);
    if (res.code === 401) {
      return ResultUtil.fail<null>(401, res.message || '登录已过期');
    }
    if (res.code === 200) {
      return ResultUtil.success(null);
    }
    return ResultUtil.fail<null>(res.code, res.message || '删除任务失败');
  }
}

export const taskRepository: TaskRepository = new TaskRepository();
