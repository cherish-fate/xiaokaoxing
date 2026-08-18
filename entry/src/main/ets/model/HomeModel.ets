import { UserModel, GreetingModel } from '../model/UserModel';
import { ExamModel, ExamCountdownModel, TodayProgressModel } from '../model/ExamModel';
import { TaskModel, TodayTaskListModel } from '../model/TaskModel';
import { ResourceModel } from '../model/ResourceModel';

export class HomeModel {
  user: UserModel;
  greeting: GreetingModel;
  countdown: ExamCountdownModel;
  progress: TodayProgressModel;
  recentExams: ExamModel[];
  todayTasks: TodayTaskListModel;
  resources: ResourceModel[];

  constructor(
    user: UserModel,
    greeting: GreetingModel,
    countdown: ExamCountdownModel,
    progress: TodayProgressModel,
    recentExams: ExamModel[],
    todayTasks: TodayTaskListModel,
    resources: ResourceModel[]
  ) {
    this.user = user;
    this.greeting = greeting;
    this.countdown = countdown;
    this.progress = progress;
    this.recentExams = recentExams;
    this.todayTasks = todayTasks;
    this.resources = resources;
  }

  static empty(): HomeModel {
    const user = UserModel.empty();
    const greeting = new GreetingModel(user);
    const countdown = new ExamCountdownModel(false, '', '', '', '', 0, '');
    const progress = new TodayProgressModel(0, 0, 0);
    const tasks = new TodayTaskListModel(false, 0, 0, [], '今日暂无任务，开始添加学习计划吧');
    return new HomeModel(user, greeting, countdown, progress, [], tasks, []);
  }

  todayCompletedCount(): number {
    if (this.progress.total <= 0) {
      return 0;
    }
    return this.progress.completed;
  }

  todayPendingCount(): number {
    if (this.progress.total <= 0) {
      return 0;
    }
    return Math.max(0, this.progress.total - this.progress.completed);
  }
}
