import { promptAction } from '@kit.ArkUI';
import { homeRepository } from '../repository/HomeRepository';
import { HomeModel } from '../model/HomeModel';
import { GreetingBar } from '../components/GreetingBar';
import { CountdownCard } from '../components/CountdownCard';
import { ExamScheduleSection } from '../components/ExamScheduleSection';
import { TodayTaskSection } from '../components/TodayTaskSection';
import { RecommendResourceSection } from '../components/RecommendResourceSection';
import { BottomTabBar, TabIndex } from '../components/BottomTabBar';
import { LoadingView, ErrorView } from '../components/StateViews';
import { AppColors } from '../utils/Constants';
import { RouterUtil } from '../utils/RouterUtil';
import { RouteUrls } from '../utils/RouteUrls';
import { ToastUtil } from '../utils/ToastUtil';
import { Logger } from '../utils/Logger';
import { TaskModel, TodayTaskListModel } from '../model/TaskModel';

const TAG = 'HomePage';

enum PageState {
  LOADING = 'loading',
  CONTENT = 'content',
  ERROR = 'error'
}

@Entry
@Component
struct HomePage {
  @State pageState: PageState = PageState.LOADING;
  @State homeData: HomeModel = HomeModel.empty();
  @State currentTab: number = TabIndex.HOME;
  @State errorMessage: string = '';
  @State isRefreshing: boolean = false;
  private isFirstShow: boolean = true;

  aboutToAppear(): void {
    this.loadData();
  }

  onPageShow(): void {
    if (!this.isFirstShow) {
      this.loadData();
    }
    this.isFirstShow = false;
  }

  private async loadData(): Promise<void> {
    this.pageState = PageState.LOADING;
    try {
      const result = await homeRepository.loadHomeData();
      if (result.success && result.data) {
        this.homeData = result.data;
        this.pageState = PageState.CONTENT;
      } else if (result.code === 401) {
        ToastUtil.show('登录已过期，请重新登录');
        RouterUtil.toLogin();
      } else {
        this.errorMessage = result.message || '加载失败';
        this.pageState = PageState.ERROR;
      }
    } catch (e) {
      Logger.error(TAG, 'loadData failed', e as Error);
      this.errorMessage = '网络异常，请检查网络连接';
      this.pageState = PageState.ERROR;
    }
  }

  private async onRefresh(): Promise<void> {
    if (this.isRefreshing) {
      return;
    }
    this.isRefreshing = true;
    try {
      const result = await homeRepository.loadHomeData();
      if (result.success && result.data) {
        this.homeData = result.data;
        this.pageState = PageState.CONTENT;
      } else if (result.code === 401) {
        ToastUtil.show('登录已过期，请重新登录');
        RouterUtil.toLogin();
      } else {
        ToastUtil.show(result.message || '刷新失败');
      }
    } catch (e) {
      Logger.error(TAG, 'onRefresh failed', e as Error);
      ToastUtil.show('网络异常');
    } finally {
      this.isRefreshing = false;
    }
  }

  private applyTaskState(id: number, completed: boolean): void {
    const newList: TaskModel[] = this.homeData.todayTasks.list.map((t: TaskModel) => {
      if (t.id === id) {
        return new TaskModel(t.id, t.taskName, t.planDate, completed);
      }
      return t;
    });
    const completedCount = newList.filter((t: TaskModel) => t.isCompleted).length;
    const newTasks: TodayTaskListModel = new TodayTaskListModel(
      newList.length > 0,
      newList.length,
      completedCount,
      newList,
      this.homeData.todayTasks.emptyHint
    );
    this.homeData = new HomeModel(
      this.homeData.user,
      this.homeData.greeting,
      this.homeData.countdown,
      this.homeData.progress,
      this.homeData.recentExams,
      newTasks,
      this.homeData.resources
    );
  }

  private async onToggleTask(id: number, completed: boolean): Promise<void> {
    const originCompleted = !completed;
    // 乐观更新：先改 UI，再请求后端
    this.applyTaskState(id, completed);
    try {
      const result = await homeRepository.refreshTaskStatus(id, completed);
      if (!result.success) {
        // 失败回滚
        this.applyTaskState(id, originCompleted);
        if (result.code === 401) {
          ToastUtil.show('登录已过期，请重新登录');
          RouterUtil.toLogin();
        } else {
          ToastUtil.show(result.message || '更新失败');
        }
      }
    } catch (e) {
      this.applyTaskState(id, originCompleted);
      Logger.error(TAG, 'onToggleTask failed', e as Error);
      ToastUtil.show('网络异常，请稍后重试');
    }
  }

  private async onDeleteExam(id: number): Promise<void> {
    try {
      const confirmed = await this.showConfirm('确定删除该考试吗？');
      if (!confirmed) {
        return;
      }
      const result = await homeRepository.deleteExam(id);
      if (result.success) {
        ToastUtil.show('删除成功');
        this.loadData();
      } else {
        ToastUtil.show(result.message || '删除失败');
      }
    } catch (e) {
      Logger.error(TAG, 'onDeleteExam failed', e as Error);
      ToastUtil.show('删除失败');
    }
  }

  private showConfirm(msg: string): Promise<boolean> {
    return new Promise((resolve: (v: boolean) => void) => {
      promptAction.showDialog({
        message: msg,
        buttons: [
          { text: '取消', color: '#666666' },
          { text: '确定', color: AppColors.PRIMARY }
        ]
      }).then((result: promptAction.ShowDialogSuccessResponse) => {
        resolve(result.index === 1);
      }).catch(() => {
        resolve(false);
      });
    });
  }

  build() {
    Stack({ alignContent: Alignment.Bottom }) {
      Column() {
        if (this.pageState === PageState.LOADING) {
          Column() {
            LoadingView({ message: '正在加载首页...' })
          }
          .width('100%')
          .layoutWeight(1)
        } else if (this.pageState === PageState.ERROR) {
          Column() {
            ErrorView({
              message: this.errorMessage,
              onRetry: () => this.loadData()
            })
          }
          .width('100%')
          .layoutWeight(1)
        } else {
          Column() {
            this.ContentArea()
          }
          .width('100%')
          .layoutWeight(1)
        }
      }
      .width('100%')
      .height('100%')

      BottomTabBar({
        currentIndex: this.currentTab,
        onChange: (index: number) => {
          this.currentTab = index;
        }
      })
    }
    .width('100%')
    .height('100%')
    .backgroundColor(AppColors.BG)
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP])
  }

  @Builder
  ContentArea() {
    Refresh({ refreshing: this.isRefreshing, friction: 100 }) {
      Scroll() {
        Column({ space: 16 }) {
          GreetingBar({
            greetingText: this.homeData.greeting.displayText(),
            avatarUrl: this.homeData.user.avatarUrl
          })

          Column() {
            CountdownCard({
              countdown: this.homeData.countdown,
              progress: this.homeData.progress,
              onAddExam: () => {
                RouterUtil.push(RouteUrls.EXAM_ADD);
              }
            })
          }
          .padding({ left: 20, right: 20 })

          ExamScheduleSection({
            exams: this.homeData.recentExams,
            completedCount: this.homeData.progress.completed,
            pendingCount: Math.max(0, this.homeData.progress.total - this.homeData.progress.completed),
            onDelete: (id: number) => this.onDeleteExam(id)
          })

          TodayTaskSection({
            taskList: this.homeData.todayTasks,
            onToggle: (id: number, completed: boolean) => this.onToggleTask(id, completed)
          })

          RecommendResourceSection({
            resources: this.homeData.resources
          })
        }
        .padding({ bottom: 110 })
      }
      .scrollBar(BarState.Off)
      .edgeEffect(EdgeEffect.Spring)
    }
    .onStateChange((refreshState: RefreshStatus) => {
      if (refreshState === RefreshStatus.Refresh) {
        this.onRefresh();
      }
    })
    .width('100%')
    .height('100%')
  }
}
