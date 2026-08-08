@Observed
export class TaskModel {
  id: number;
  taskName: string;
  planDate: string;
  isCompleted: boolean;

  constructor(id: number, taskName: string, planDate: string, isCompleted: boolean) {
    this.id = id;
    this.taskName = taskName;
    this.planDate = planDate;
    this.isCompleted = isCompleted;
  }

  toggle(): void {
    this.isCompleted = !this.isCompleted;
  }
}

@Observed
export class TodayTaskListModel {
  hasTasks: boolean;
  total: number;
  completed: number;
  list: TaskModel[];
  emptyHint: string;

  constructor(hasTasks: boolean, total: number, completed: number, list: TaskModel[], emptyHint: string) {
    this.hasTasks = hasTasks;
    this.total = total;
    this.completed = completed;
    this.list = list;
    this.emptyHint = emptyHint;
  }
}
