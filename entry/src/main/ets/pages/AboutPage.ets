import { AppColors, AppText } from '../utils/Constants';
import { LoadingView, ErrorView } from '../components/StateViews';
import { RouterUtil } from '../utils/RouterUtil';
import { ToastUtil } from '../utils/ToastUtil';
import { MeAboutInfoModel } from '../model/MeModel';
import { meRepository } from '../repository/MeRepository';

enum PageState {
  LOADING = 'LOADING',
  CONTENT = 'CONTENT',
  ERROR = 'ERROR'
}

interface AboutFeatureItem {
  icon: ResourceStr | string;
  iconBg: string;
  iconColor: string;
  title: string;
  desc: string;
}

class AboutFeatureList {
  static readonly ALL: AboutFeatureItem[] = [
    {
      icon: '📅',
      iconBg: '#E6EEFF',
      iconColor: AppColors.PRIMARY,
      title: '考试日历',
      desc: '倒计时提醒，不错过每场考试'
    },
    {
      icon: '✅',
      iconBg: '#E8F8EE',
      iconColor: '#34C759',
      title: '每日任务',
      desc: '科学规划，打卡养成学习习惯'
    },
    {
      icon: '📚',
      iconBg: '#FFF4E6',
      iconColor: '#FF9F0A',
      title: '资源库',
      desc: '真题、笔记、书签，一键收藏'
    },
    {
      icon: '🤝',
      iconBg: '#F4E8FF',
      iconColor: '#7330D1',
      title: '学习社区',
      desc: '组队打卡、考点投票，与同学共同进步'
    },
    {
      icon: '🧠',
      iconBg: '#EFF4FF',
      iconColor: AppColors.PRIMARY,
      title: 'AI 问答',
      desc: '智能答疑，随问随答'
    }
  ];
}

@Entry
@Component
struct AboutPage {
  @State pageState: PageState = PageState.LOADING;
  @State errorMsg: string = '';
  @State about: MeAboutInfoModel = MeAboutInfoModel.empty();
  @State cacheSizeText: string = '计算中';
  @State hasUpdate: boolean = false;

  aboutToAppear(): void {
    this.loadData();
  }

  private async loadData(): Promise<void> {
    this.pageState = PageState.LOADING;
    const res = await meRepository.loadAboutInfo();
    if (!res.data) {
      this.pageState = PageState.ERROR;
      this.errorMsg = res.message || '加载失败';
      return;
    }
    this.about = res.data;
    this.cacheSizeText = '12.3 MB';
    this.pageState = PageState.CONTENT;
  }

  private onRetry(): void {
    this.loadData();
  }

  private onBack(): void {
    RouterUtil.back();
  }

  private onShareToFriend(): void {
    ToastUtil.show('推荐给好友功能开发中');
  }

  private onCheckUpdate(): void {
    ToastUtil.show(this.hasUpdate ? '发现新版本，请前往应用商店更新' : '已是最新版本');
  }

  private onClearCache(): void {
    ToastUtil.show('缓存已清除');
    this.cacheSizeText = '0 MB';
  }

  private onOpenPrivacy(): void {
    if (this.about.privacyUrl && this.about.privacyUrl.length > 0) {
      ToastUtil.show('打开《隐私政策》');
    } else {
      ToastUtil.show('《隐私政策》暂未上线');
    }
  }

  private onOpenTerms(): void {
    if (this.about.termsUrl && this.about.termsUrl.length > 0) {
      ToastUtil.show('打开《用户服务协议》');
    } else {
      ToastUtil.show('《用户服务协议》暂未上线');
    }
  }

  private onOpenWebsite(): void {
    if (this.about.website && this.about.website.length > 0) {
      ToastUtil.show(`打开官网：${this.about.website}`);
    }
  }

  private onOpenSupportEmail(): void {
    if (this.about.supportEmail && this.about.supportEmail.length > 0) {
      ToastUtil.show(`联系邮箱：${this.about.supportEmail}`);
    }
  }

  private appLogoText(): string {
    const name: string = this.about.appName || AppText.APP_NAME;
    return name.length > 0 ? name.charAt(0) : '星';
  }

  @Builder
  NavBar() {
    Row() {
      Image($r('app.media.examDetail_back'))
        .width(40)
        .height(40)
        .padding(10)
        .backgroundColor(AppColors.CARD)
        .borderRadius(20)
        .onClick(() => this.onBack())

      Text('关于校考星')
        .fontSize(17)
        .fontWeight(FontWeight.Bold)
        .fontColor(AppColors.TEXT_PRIMARY)
        .layoutWeight(1)
        .textAlign(TextAlign.Center)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
    }
    .width('100%')
    .height(56)
    .padding({ left: 8, right: 8 })
    .backgroundColor(Color.White)
  }

  @Builder
  BrandHeader() {
    Column({ space: 12 }) {
      Text(this.appLogoText())
        .fontSize(32)
        .fontWeight(FontWeight.Bold)
        .fontColor(AppColors.PRIMARY)
        .width(72)
        .height(72)
        .textAlign(TextAlign.Center)
        .borderRadius(20)
        .backgroundColor('rgba(255,255,255,0.95)')
        .shadow({ radius: 8, color: 'rgba(0,0,0,0.10)' })

      Text(this.about.appName || AppText.APP_NAME)
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .fontColor('#FFFFFF')
        .letterSpacing(1)
        .margin({ top: 0 })

      Text(this.about.versionDisplay())
        .fontSize(12)
        .fontColor('rgba(255,255,255,0.80)')
    }
    .width('100%')
    .padding({ top: 28, bottom: 24, left: 16, right: 16 })
    .borderRadius(18)
    .linearGradient({
      direction: GradientDirection.RightBottom,
      colors: [[0x5B8BFF, 0.0], [0x4A7FFF, 1.0]]
    })
    .shadow({ radius: 12, color: 'rgba(74,127,255,0.25)' })
  }

  @Builder
  SectionLabel(title: string) {
    Text(title)
      .width('100%')
      .fontSize(13)
      .fontWeight(FontWeight.Bold)
      .fontColor(AppColors.TEXT_SECONDARY)
      .margin({ left: 4, bottom: 8, top: 0 })
  }


  @Builder
  FormDivider() {
    Divider()
      .color(AppColors.DIVIDER)
      .strokeWidth(1)
      .margin({ left: 16, right: 16 })
  }

  @Builder
  IntroCard() {
    Column({ space: 0 }) {
      Text(this.about.description || MeAboutInfoModel.empty().description)
        .fontSize(13)
        .lineHeight(20)
        .fontColor(AppColors.TEXT_SECONDARY)
        .width('100%')
        .padding({ left: 16, right: 16, top: 18, bottom: 18 })
    }
    .width('100%')
    .backgroundColor(AppColors.CARD)
    .border({ width: 1, color: AppColors.DIVIDER })
    .borderRadius(18)
    .shadow({ radius: 12, color: 'rgba(0,0,0,0.04)' })

  }

  @Builder
  FeatureRow(item: AboutFeatureItem) {
    Row({ space: 12 }) {
      Text(item.icon as string)
        .fontSize(16)
        .width(36)
        .height(36)
        .textAlign(TextAlign.Center)
        .borderRadius(12)
        .backgroundColor(item.iconBg)

      Column({ space: 2 }) {
        Text(item.title)
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .fontColor(AppColors.TEXT_PRIMARY)
          .width('100%')
        Text(item.desc)
          .fontSize(12)
          .fontColor(AppColors.TEXT_HINT)
          .lineHeight(16)
          .width('100%')
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .layoutWeight(1)
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 14, bottom: 14 })
  }

  @Builder
  FeatureCard() {
    Column({ space: 0 }) {
      ForEach(AboutFeatureList.ALL, (item: AboutFeatureItem, index: number) => {
        if (index > 0) {
          this.FormDivider()
        }
        this.FeatureRow(item)
      }, (item: AboutFeatureItem, index: number) => `${index}-${item.title}`)
    }
    .width('100%')
    .backgroundColor(AppColors.CARD)
    .border({ width: 1, color: AppColors.DIVIDER })
    .borderRadius(18)
    .shadow({ radius: 12, color: 'rgba(0,0,0,0.04)' })
  }

  @Builder
  ContactRow(label: string, value: string, isBrand: boolean, onClick: () => void) {
    Row({ space: 8 }) {
      Text(label)
        .fontSize(12)
        .fontColor(AppColors.TEXT_HINT)
        .width(48)
      Text(value)
        .fontSize(12)
        .lineHeight(18)
        .fontColor(isBrand ? AppColors.PRIMARY : AppColors.TEXT_SECONDARY)
        .layoutWeight(1)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
    }
    .width('100%')
    .onClick(()=>{onClick()})
  }

  @Builder
  ContactGroup() {
    Column({ space: 6 }) {
      this.ContactRow('开发方', this.about.team, false, () => {})
      if (this.about.website && this.about.website.length > 0) {
        this.ContactRow('官网', this.about.website, true, () => this.onOpenWebsite())

      }
      if (this.about.supportEmail && this.about.supportEmail.length > 0) {
        this.ContactRow('邮箱', this.about.supportEmail, true, () => this.onOpenSupportEmail())

      }
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 14, bottom: 14 })
  }

  @Builder
  LinkRow(
    icon: string,
    iconBg: string,
    label: string,
    isBrandLabel: boolean,
    value: string,
    onClick: () => void
  ) {
    Row({ space: 12 }) {
      Text(icon)
        .fontSize(13)
        .width(28)
        .height(28)
        .textAlign(TextAlign.Center)
        .borderRadius(8)
        .backgroundColor(iconBg)

      Text(label)
        .fontSize(14)
        .fontColor(isBrandLabel ? AppColors.PRIMARY : AppColors.TEXT_PRIMARY)
        .layoutWeight(1)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })

      if (value.length > 0) {
        Text(value)
          .fontSize(13)
          .fontColor(AppColors.TEXT_HINT)
          .margin({ right: 4 })
      }

      Text('›')
        .fontSize(18)
        .fontColor(AppColors.TEXT_HINT)
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 14, bottom: 14 })
    .onClick(() => onClick())
  }

  @Builder
  ContactCard() {
    Column({ space: 0 }) {
      this.ContactGroup()
      this.FormDivider()
      this.LinkRow('📄', '#EFF4FF', '《隐私政策》', true, '', () => this.onOpenPrivacy())
      this.FormDivider()
      this.LinkRow('📋', '#EFF4FF', '《用户服务协议》', true, '', () => this.onOpenTerms())
    }
    .width('100%')
    .backgroundColor(AppColors.CARD)
    .border({ width: 1, color: AppColors.DIVIDER })
    .borderRadius(18)
    .shadow({ radius: 12, color: 'rgba(0,0,0,0.04)' })
  }

  @Builder
  OtherCard() {
    Column({ space: 0 }) {
      this.LinkRow('⭐', '#FFF4E6', '推荐给好友', false, '', () => this.onShareToFriend())
      this.FormDivider()
      this.LinkRow(
        '🔄',
        '#E6EEFF',
        '检查更新',
        false,
        this.hasUpdate ? '发现新版本' : '已是最新',
        () => this.onCheckUpdate()
      )
      this.FormDivider()
      this.LinkRow('🧹', '#FDECEC', '清除缓存', false, this.cacheSizeText, () => this.onClearCache())
    }
    .width('100%')
    .backgroundColor(AppColors.CARD)
    .border({ width: 1, color: AppColors.DIVIDER })
    .borderRadius(18)
    .shadow({ radius: 12, color: 'rgba(0,0,0,0.04)' })
  }

  @Builder
  CopyrightFooter() {
    Text(this.about.copyright || MeAboutInfoModel.empty().copyright)
      .fontSize(11)
      .fontColor(AppColors.TEXT_HINT)
      .textAlign(TextAlign.Center)
      .width('100%')
      .padding({ top: 16, bottom: 8, left: 16, right: 16 })
  }

  @Builder
  ContentView() {
    Column({ space: 16 }) {
      this.BrandHeader()

      Column({ space: 0 }) {
        this.SectionLabel('应用简介')
        this.IntroCard()
      }
      .width('100%')

      Column({ space: 0 }) {
        this.SectionLabel('核心功能')
        this.FeatureCard()
      }
      .width('100%')

      Column({ space: 0 }) {
        this.SectionLabel('联系与支持')
        this.ContactCard()
      }
      .width('100%')

      Column({ space: 0 }) {
        this.SectionLabel('其他')
        this.OtherCard()
      }
      .width('100%')

      this.CopyrightFooter()
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 12, bottom: 24 })
  }

  build() {
    Column() {
      this.NavBar()
      if (this.pageState === PageState.LOADING) {
        Column() {
          LoadingView({ message: '加载中...' })
        }
        .width('100%')
        .layoutWeight(1)
      } else if (this.pageState === PageState.ERROR) {
        Column() {
          ErrorView({
            message: this.errorMsg,
            onRetry: () => this.onRetry()
          })
        }
        .width('100%')
        .layoutWeight(1)
      } else {
        Scroll() {
          this.ContentView()
        }
        .scrollBar(BarState.Off)
        .width('100%')
        .layoutWeight(1)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(AppColors.BG)
  }
}
