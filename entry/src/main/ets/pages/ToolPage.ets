import { router } from '@kit.ArkUI';
import { AppColors, AppSize, TagStyle } from '../utils/Constants';
import { ToastUtil } from '../utils/ToastUtil';
import { Logger } from '../utils/Logger';
import { ToolPageModel, NoteTagCountModel } from '../model/ToolModel';
import { toolRepository } from '../repository/ToolRepository';
import { BottomTabBar, TabIndex } from '../components/BottomTabBar';
import { LoadingView, EmptyView, ErrorView } from '../components/StateViews';
import { RouterUtil } from '../utils/RouterUtil';
import { RouteUrls } from '../utils/RouteUrls';

const TAG = 'ToolPage';

@Entry
@Component
struct ToolPage {
  @State pageState: string = 'LOADING';
  @State errorMsg: string = '';
  @State model: ToolPageModel = ToolPageModel.empty();
  @State greeting: string = '今天也是充实的一天 🌟';
  private isFirstShow: boolean = true;

  async aboutToAppear(): Promise<void> {
    this.updateGreeting();
    this.pageState = 'LOADING';
    await this.loadData();
  }

  onPageShow(): void {
    // 首次展示由 aboutToAppear 负责加载，跳过避免重复
    if (this.isFirstShow) {
      this.isFirstShow = false;
      return;
    }
    // 从子页面（如笔记页）返回时刷新数据，确保笔记数量等及时更新
    if (this.pageState === 'CONTENT') {
      this.loadData();
    }
  }

  private updateGreeting(): void {
    const hour: number = new Date().getHours();
    if (hour < 6) {
      this.greeting = '夜深了，注意休息 🌙';
    } else if (hour < 11) {
      this.greeting = '早上好，开启高效的一天 ☀️';
    } else if (hour < 14) {
      this.greeting = '中午好，吃了饭继续冲 🍜';
    } else if (hour < 18) {
      this.greeting = '下午好，来刷个每日一题吧 📚';
    } else {
      this.greeting = '晚上好，今天也是充实的一天 🌟';
    }
  }

  private async loadData(): Promise<void> {
    const res = await toolRepository.loadToolboxHome();
    if (res.code === 401) {
      this.pageState = 'ERROR';
      this.errorMsg = res.message || '登录已过期，请重新登录';
      setTimeout(() => RouterUtil.toLogin(), 800);
      return;
    }
    if (!res.success || !res.data) {
      this.pageState = 'ERROR';
      this.errorMsg = res.message || '加载失败';
      return;
    }
    this.model = res.data;
    this.pageState = 'CONTENT';
  }

  private async onRetry(): Promise<void> {
    this.pageState = 'LOADING';
    await this.loadData();
  }

  onDailyQuestionTap(): void {
    RouterUtil.push(RouteUrls.DAILY_QUESTION);
  }

  onNotesTap(): void {
    RouterUtil.push(RouteUrls.NOTE_LIST);
  }

  onGpaTap(): void {
    RouterUtil.push(RouteUrls.GPA);
  }

  onDocsTap(): void {
    RouterUtil.push(RouteUrls.DOCUMENT_LIST);
  }

  onBookmarksTap(): void {
    RouterUtil.push(RouteUrls.BOOKMARK_LIST);
  }

  // ========== 构建 ==========
  build() {
    Column() {
      this.Header()

      Stack({ alignContent: Alignment.Bottom }) {
        if (this.pageState === 'LOADING') {
          Column() {
            LoadingView({ message: '工具箱加载中…' })
          }
          .width('100%')
          .height('100%')
        } else if (this.pageState === 'ERROR') {
          Column() {
            ErrorView({ message: this.errorMsg, onRetry: () => this.onRetry() })
          }
          .width('100%')
          .height('100%')
        } else {
          Scroll() {
            Column() {
              Column({ space: 12 }) {
                this.DailyQuestionCard()
                this.ToolGrid()
              }
              .margin({ top: 12, left: 16, right: 16 })

              Blank(100)
            }
            .width('100%')
          }
          .width('100%')
          .height('100%')
          .scrollBar(BarState.Off)
          .edgeEffect(EdgeEffect.Spring)
        }

        BottomTabBar({ currentIndex: TabIndex.TOOL })
      }
      .layoutWeight(1)
      .width('100%')
    }
    .width('100%')
    .height('100%')
    .backgroundColor(AppColors.BG)
  }

  // ========== Header ==========
  @Builder
  Header() {
    Row() {
      Column({ space: 4 }) {
        Text('备考工具箱')
          .fontSize(26)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.TEXT_PRIMARY)
          .letterSpacing(-0.5)
        Text(this.greeting)
          .fontSize(13)
          .fontColor(AppColors.TEXT_HINT)
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
    }
    .width('100%')
    .padding({ left: 20, right: 20, top: 16, bottom: 12 })
    .backgroundColor(Color.White)
  }

  // ========== 每日一问通栏 ==========
  @Builder
  DailyQuestionCard() {
    Row({ space: 14 }) {
      Stack() {
        Column() {
          Row() {
            Text(this.model.dailyQuestion.hasAnswered ? '✅' : '❓')
              .fontSize(22)
          }
          .width('100%')
          .height('100%')
          .justifyContent(FlexAlign.Center)
        }
        .width(44)
        .height(44)
        .borderRadius(14)
        .backgroundColor('#FFF0F0')
      }
      .width(44)
      .height(44)

      Column({ space: 4 }) {
        Row({ space: 6 }) {
          Text('每日一问')
            .fontSize(10)
            .fontWeight(FontWeight.Bold)
            .fontColor('#F54141')
            .padding({ left: 8, right: 8, top: 2, bottom: 2 })
            .borderRadius(6)
            .backgroundColor('#FFF0F0')
          if (this.model.dailyQuestion.hasAnswered) {
            Text('今日已答')
              .fontSize(10)
              .fontWeight(FontWeight.Bold)
              .fontColor('#38CFC9')
              .padding({ left: 8, right: 8, top: 2, bottom: 2 })
              .borderRadius(6)
              .backgroundColor('#E6F7F5')
          }
        }
        .width('100%')

        Text(this.model.dailyQuestion.question || '今天的每日一问还在更新中')
          .fontSize(14)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.TEXT_PRIMARY)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .width('100%')

        Text(`${this.model.dailyQuestion.subject || '每日精进'} `)
          .fontSize(11)
          .fontColor(AppColors.TEXT_HINT)
          .width('100%')
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)

      Text('›')
        .fontSize(20)
        .fontColor('#CCCCCC')
        .margin({ left: 4 })
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 14, bottom: 14 })
    .borderRadius(18)
    .backgroundColor(Color.White)
    .shadow({ radius: 12, color: 'rgba(0,0,0,0.04)' })
    .border({ width: 1, color: 'rgba(0,0,0,0.04)' })
    .onClick(() => this.onDailyQuestionTap())
  }

  // ========== 工具栅格（2 列统一尺寸）==========
  @Builder
  ToolGrid() {
    Grid() {
      GridItem() {
        this.NotesCard()
      }

      GridItem() {
        this.GpaCard()
      }

      GridItem() {
        this.DocsCard()
      }

      GridItem() {
        this.BookmarksCard()
      }
    }
    .columnsTemplate('1fr 1fr')
    .rowsTemplate('1fr 1fr')
    .columnsGap(12)
    .rowsGap(12)
    .width('100%')
    .aspectRatio(1)
  }

  // ========== 学习笔记卡 ==========
  @Builder
  NotesCard() {
    Column({ space: 10 }) {
      Column() {
        Row() {
          Text('📝')
            .fontSize(20)
        }
        .width(40)
        .height(40)
        .borderRadius(12)
        .backgroundColor(TagStyle.PURPLE)
        .justifyContent(FlexAlign.Center)
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)

      Column({ space: 3 }) {
        Text('学习笔记')
          .fontSize(14)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.TEXT_PRIMARY)
          .width('100%')
        Text('摘录 · 编辑 · 云同步')
          .fontSize(11)
          .fontColor(AppColors.TEXT_HINT)
          .width('100%')
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)

      Row() {
        Text(this.model.notes.count.toString())
          .fontSize(22)
          .fontWeight(FontWeight.Bold)
          .fontColor('#7330D1')
        Text(' 篇')
          .fontSize(13)
          .fontColor(AppColors.TEXT_HINT)
          .fontWeight(FontWeight.Medium)
      }
      .width('100%')
      .margin({ top: -2 })
      .justifyContent(FlexAlign.Start)
    }
    .width('100%')
    .height('100%')
    .padding(16)
    .borderRadius(18)
    .backgroundColor(Color.White)
    .shadow({ radius: 12, color: 'rgba(0,0,0,0.04)' })
    .border({ width: 1, color: 'rgba(0,0,0,0.03)' })
    .alignItems(HorizontalAlign.Start)
    .onClick(() => this.onNotesTap())
  }

  // ========== 绩点计算器卡 ==========
  @Builder
  GpaCard() {
    Column({ space: 10 }) {
      Column() {
        Row() {
          Text('📊')
            .fontSize(20)
        }
        .width(40)
        .height(40)
        .borderRadius(12)
        .backgroundColor(TagStyle.GREEN)
        .justifyContent(FlexAlign.Center)
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)

      Column({ space: 3 }) {
        Text('绩点计算器')
          .fontSize(14)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.TEXT_PRIMARY)
          .width('100%')
        Text('保研线 · 挂科预测')
          .fontSize(11)
          .fontColor(AppColors.TEXT_HINT)
          .width('100%')
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)

      Row() {
        Text(this.model.gpa.currentDisplay())
          .fontSize(22)
          .fontWeight(FontWeight.Bold)
          .fontColor('#38CFC9')
      }
      .width('100%')
      .margin({ top: -2 })
      .justifyContent(FlexAlign.Start)

      if (this.model.gpa.trend !== 0) {
        Row({ space: 4 }) {
          Text(this.model.gpa.trendDisplay())
            .fontSize(10)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.model.gpa.trendColor())
        }
        .width('100%')
        .justifyContent(FlexAlign.Start)
      } else if (this.model.gpa.semester.length > 0) {
        Row({ space: 4 }) {
          Text(this.model.gpa.semester)
            .fontSize(10)
            .fontColor(AppColors.TEXT_HINT)
        }
        .width('100%')
        .justifyContent(FlexAlign.Start)
      }
    }
    .width('100%')
    .height('100%')
    .padding(16)
    .borderRadius(18)
    .backgroundColor(Color.White)
    .shadow({ radius: 12, color: 'rgba(0,0,0,0.04)' })
    .border({ width: 1, color: 'rgba(0,0,0,0.03)' })
    .alignItems(HorizontalAlign.Start)
    .onClick(() => this.onGpaTap())
  }

  // ========== 个人文档库卡 ==========
  @Builder
  DocsCard() {
    Column({ space: 10 }) {
      Column() {
        Row() {
          Text('📁')
            .fontSize(20)
        }
        .width(40)
        .height(40)
        .borderRadius(12)
        .backgroundColor(TagStyle.BLUE)
        .justifyContent(FlexAlign.Center)
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)

      Column({ space: 3 }) {
        Text('个人文档库')
          .fontSize(14)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.TEXT_PRIMARY)
          .width('100%')
        Text('下载 · 收藏 · 离线')
          .fontSize(11)
          .fontColor(AppColors.TEXT_HINT)
          .width('100%')
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)

      Row() {
        Text(this.model.documents.total.toString())
          .fontSize(22)
          .fontWeight(FontWeight.Bold)
          .fontColor('#4A7FFF')
        Text(' 个')
          .fontSize(13)
          .fontColor(AppColors.TEXT_HINT)
          .fontWeight(FontWeight.Medium)
      }
      .width('100%')
      .margin({ top: -2 })
      .justifyContent(FlexAlign.Start)

      Row({ space: 6 }) {
        ForEach(this.model.documents.categories.slice(0, 2), (item: NoteTagCountModel) => {
          Row() {
            Text(`${item.name} ${item.count.toString()}`)
              .fontSize(9)
              .fontColor(AppColors.TEXT_SECONDARY)
              .padding({ left: 6, right: 6, top: 2, bottom: 2 })
              .borderRadius(4)
              .backgroundColor('#F5F7FA')
              .fontWeight(FontWeight.Medium)
          }
        }, (item: NoteTagCountModel) => item.name)
      }
      .width('100%')
      .margin({ top: 2 })
    }
    .width('100%')
    .height('100%')
    .padding(16)
    .borderRadius(18)
    .backgroundColor(Color.White)
    .shadow({ radius: 12, color: 'rgba(0,0,0,0.04)' })
    .border({ width: 1, color: 'rgba(0,0,0,0.03)' })
    .alignItems(HorizontalAlign.Start)
    .onClick(() => this.onDocsTap())
  }

  // ========== 精选书签卡（暖黄渐变背景）==========
  @Builder
  BookmarksCard() {
    Column({ space: 10 }) {
      Column() {
        Row() {
          Text('🔖')
            .fontSize(20)
        }
        .width(40)
        .height(40)
        .borderRadius(12)
        .backgroundColor('rgba(255, 200, 0, 0.2)')
        .justifyContent(FlexAlign.Center)
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)

      Column({ space: 3 }) {
        Text('精选书签')
          .fontSize(14)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.TEXT_PRIMARY)
          .width('100%')
        Text('句级标注 · 速查')
          .fontSize(11)
          .fontColor('rgba(184,134,11,0.7)')
          .width('100%')
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)

      Row() {
        Text(this.model.bookmarks.total.toString())
          .fontSize(22)
          .fontWeight(FontWeight.Bold)
          .fontColor('#B8860B')
        Text(' 条')
          .fontSize(13)
          .fontColor('rgba(184,134,11,0.7)')
          .fontWeight(FontWeight.Medium)
      }
      .width('100%')
      .margin({ top: -2 })
      .justifyContent(FlexAlign.Start)
    }
    .width('100%')
    .height('100%')
    .padding(16)
    .borderRadius(18)
    .linearGradient({
      direction: GradientDirection.RightBottom,
      colors: [['#FFF9E6', 0], ['#FFF3CC', 1]]
    })
    .shadow({ radius: 12, color: 'rgba(0,0,0,0.04)' })
    .border({ width: 1, color: 'rgba(0,0,0,0.03)' })
    .alignItems(HorizontalAlign.Start)
    .onClick(() => this.onBookmarksTap())
  }
}
