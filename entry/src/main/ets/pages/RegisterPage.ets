import { promptAction, router } from '@kit.ArkUI';
import { apiService, Major, RegisterRequest } from '../api/ApiService';
import { meRepository } from '../repository/MeRepository';
import { MeAboutInfoModel } from '../model/MeModel';
import { RouterUtil } from '../utils/RouterUtil';
import { RouteUrls } from '../utils/RouteUrls';

interface MajorSelectorResult {
  index: number;
  value: string;
  majorId: number;
}

function defaultOnConfirm(result: MajorSelectorResult): void {}

@CustomDialog
struct MajorSelectorDialog {
  controller: CustomDialogController = new CustomDialogController({
    builder: () => {}
  });
  @Link majors: Major[];
  initialIndex: number = 0;
  @State tempIndex: number = 0;
  onConfirm: (result: MajorSelectorResult) => void = defaultOnConfirm;

  aboutToAppear(): void {
    this.tempIndex = this.initialIndex < 0 ? 0 : this.initialIndex;
  }

  build() {
    Column() {
      Text($r('app.string.register_major_select_hint'))
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .margin({ top: 16, bottom: 8 })

      TextPicker({ range: this.majors.map((m: Major) => m.name), selected: this.tempIndex })
        .layoutWeight(1)
        .onChange((value: string | string[], index: number | number[]) => {
          this.tempIndex = index as number;
        })

      Row() {
        Button('取消')
          .layoutWeight(1)
          .height(44)
          .backgroundColor($r('app.color.card_bg'))
          .fontColor($r('app.color.text_secondary'))
          .borderRadius(12)
          .onClick(() => {
            this.controller.close();
          })

        Blank()
          .width(12)

        Button('确定')
          .layoutWeight(1)
          .height(44)
          .backgroundColor($r('app.color.primary_color'))
          .fontColor(Color.White)
          .borderRadius(12)
          .onClick(() => {
            const idx: number = this.tempIndex < 0 ? 0 : this.tempIndex;
            const major: Major = this.majors[idx];
            this.onConfirm({ index: idx, value: major.name, majorId: major.id });
            this.controller.close();
          })
      }
      .width('100%')
      .padding({ left: 16, right: 16, bottom: 16, top: 8 })
    }
    .width('100%')
    .height(360)
    .backgroundColor($r('app.color.bg_color'))
    .borderRadius({ topLeft: 20, topRight: 20 })
  }
}

@Entry
@Component
struct RegisterPage {
  @State nickname: string = '';
  @State school: string = '';
  @State majorIndex: number = -1;
  @State selectedMajorId: number = -1;
  @State selectedMajorName: string = '';
  @State email: string = '';
  @State password: string = '';
  @State confirmPassword: string = '';
  @State majors: Major[] = [];
  @State isLoadingMajors: boolean = true;
  @State isSubmitting: boolean = false;
  @State agreed: boolean = false;
  @State aboutInfo: MeAboutInfoModel = MeAboutInfoModel.empty();

  private majorDialogController: CustomDialogController = new CustomDialogController({
    builder: MajorSelectorDialog({
      majors: $majors,
      initialIndex: this.majorIndex,
      onConfirm: (result: MajorSelectorResult): void => {
        this.majorIndex = result.index;
        this.selectedMajorId = result.majorId;
        this.selectedMajorName = result.value;
      }
    }),
    alignment: DialogAlignment.Bottom,
    customStyle: true,
    autoCancel: true,
    offset: { dx: 0, dy: 0 }
  });

  aboutToAppear(): void {
    this.loadMajors();
    this.loadAboutInfo();
  }

  private async loadAboutInfo(): Promise<void> {
    const res = await meRepository.loadAboutInfo();
    if (res.success && res.data) {
      this.aboutInfo = res.data;
    }
  }

  private async loadMajors(): Promise<void> {
    this.isLoadingMajors = true;
    try {
      const res = await apiService.getMajors();
      if (res.code === 200 && res.data) {
        this.majors = res.data;
      } else {
        this.showToast(res.message || '加载专业列表失败');
      }
    } catch (e) {
      this.showToast('加载专业列表失败，请检查网络');
    } finally {
      this.isLoadingMajors = false;
    }
  }

  private showToast(message: Resource | string): void {
    promptAction.showToast({ message, duration: 2000 });
  }

  private isValidEmail(email: string): boolean {
    const regExp = /^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$/;
    return regExp.test(email);
  }

  private async handleRegister(): Promise<void> {
    if (this.isSubmitting) {
      return;
    }

    if (!this.agreed) {
      this.showToast('请先阅读并同意用户协议和隐私政策');
      return;
    }

    if (this.nickname.trim().length === 0) {
      this.showToast('昵称不能为空');
      return;
    }
    if (this.school.trim().length === 0) {
      this.showToast('学校名称不能为空');
      return;
    }
    if (this.selectedMajorId <= 0) {
      this.showToast('请选择专业');
      return;
    }
    if (this.email.trim().length === 0) {
      this.showToast('邮箱不能为空');
      return;
    }
    if (!this.isValidEmail(this.email.trim())) {
      this.showToast('邮箱格式不正确');
      return;
    }
    if (this.password.length < 6) {
      this.showToast('密码至少6位');
      return;
    }
    if (this.password !== this.confirmPassword) {
      this.showToast('两次输入的密码不一致');
      return;
    }

    this.isSubmitting = true;

    const req: RegisterRequest = {
      nickname: this.nickname.trim(),
      email: this.email.trim(),
      password: this.password,
      school_name: this.school.trim(),
      major_id: this.selectedMajorId
    };

    try {
      const res = await apiService.register(req);
      if (res.code === 201) {
        this.showToast('注册成功');
        setTimeout(() => {
          router.replaceUrl({ url: 'pages/Login' });
        }, 1500);
      } else if (res.code === 409) {
        this.showToast('该邮箱已注册，请直接登录');
      } else {
        this.showToast(res.message || '注册失败，请重试');
      }
    } catch (e) {
      this.showToast('网络请求失败，请稍后重试');
    } finally {
      this.isSubmitting = false;
    }
  }

  private openTerms(): void {
    if (this.aboutInfo.termsUrl && this.aboutInfo.termsUrl.length > 0) {
      const params: Record<string, Object> = {
        'title': '用户协议',
        'url': this.aboutInfo.termsUrl
      };
      RouterUtil.pushWithParams(RouteUrls.WEB_VIEW, params);
    } else {
      this.showToast('《用户协议》暂未上线');
    }
  }

  private openPrivacy(): void {
    if (this.aboutInfo.privacyUrl && this.aboutInfo.privacyUrl.length > 0) {
      const params: Record<string, Object> = {
        'title': '隐私政策',
        'url': this.aboutInfo.privacyUrl
      };
      RouterUtil.pushWithParams(RouteUrls.WEB_VIEW, params);
    } else {
      this.showToast('《隐私政策》暂未上线');
    }
  }

  private goToLogin(): void {
    router.replaceUrl({ url: 'pages/Login' });
  }

  build() {
    Stack() {
      Scroll() {
        Column({ space: 24 }) {
          Column({ space: 8 }) {
            Stack({ alignContent: Alignment.Center }) {
              Image($r('app.media.background'))
                .width(90)
                .height(90)
                .backgroundColor($r('app.color.primary_color'))
                .borderRadius(24)
                .shadow({ radius: 12, color: 'rgba(74, 127, 255, 0.3)', offsetY: 6 })

              Image($r('app.media.index_star'))
                .width(50)
                .fillColor(Color.White)
            }

            Text($r('app.string.app_title'))
              .fontSize(36)
              .fontWeight(FontWeight.Bold)
              .fontColor($r('app.color.text_primary'))

            Text($r('app.string.app_subtitle1'))
              .fontSize(14)
              .fontColor($r('app.color.text_secondary'))
          }
          .margin({ top: 40, bottom: 16 })

          Column({ space: 16 }) {
            Text($r('app.string.register_title'))
              .fontSize(24)
              .fontWeight(FontWeight.Bold)
              .fontColor($r('app.color.text_primary'))
              .width('100%')

            TextInput({ placeholder: $r('app.string.register_nickname_hint'), text: $$this.nickname })
              .width('100%')
              .height(52)
              .placeholderColor($r('app.color.text_hint'))
              .fontSize(16)
              .fontColor($r('app.color.text_primary'))
              .backgroundColor($r('app.color.card_bg'))
              .borderRadius(16)
              .padding({ left: 16, right: 16 })

            TextInput({ placeholder: $r('app.string.register_school_hint'), text: $$this.school })
              .width('100%')
              .height(52)
              .placeholderColor($r('app.color.text_hint'))
              .fontSize(16)
              .fontColor($r('app.color.text_primary'))
              .backgroundColor($r('app.color.card_bg'))
              .borderRadius(16)
              .padding({ left: 16, right: 16 })

            Row() {
              Text(this.majorIndex < 0
                ? (this.isLoadingMajors ? '加载中...' : '请选择专业')
                : this.selectedMajorName)
                .fontSize(16)
                .fontColor(this.majorIndex < 0 ? $r('app.color.text_hint') : $r('app.color.text_primary'))
                .layoutWeight(1)
              if (!this.isLoadingMajors) {
                Text('›')
                  .fontSize(20)
                  .fontColor($r('app.color.text_hint'))
              }
            }
            .width('100%')
            .height(52)
            .backgroundColor($r('app.color.card_bg'))
            .borderRadius(16)
            .padding({ left: 16, right: 16 })
            .onClick(() => {
              if (!this.isLoadingMajors && this.majors.length > 0) {
                this.majorDialogController.open();
              } else if (this.isLoadingMajors) {
                this.showToast('专业列表加载中，请稍候');
              } else {
                this.showToast('专业列表加载失败，请重试');
              }
            })

            TextInput({ placeholder: $r('app.string.register_email_hint'), text: $$this.email })
              .width('100%')
              .height(52)
              .type(InputType.Email)
              .placeholderColor($r('app.color.text_hint'))
              .fontSize(16)
              .fontColor($r('app.color.text_primary'))
              .backgroundColor($r('app.color.card_bg'))
              .borderRadius(16)
              .padding({ left: 16, right: 16 })

            TextInput({ placeholder: $r('app.string.register_password_hint'), text: $$this.password })
              .width('100%')
              .height(52)
              .type(InputType.Password)
              .placeholderColor($r('app.color.text_hint'))
              .fontSize(16)
              .fontColor($r('app.color.text_primary'))
              .backgroundColor($r('app.color.card_bg'))
              .borderRadius(16)
              .padding({ left: 16, right: 16 })

            TextInput({ placeholder: $r('app.string.register_confirm_password_hint'), text: $$this.confirmPassword })
              .width('100%')
              .height(52)
              .type(InputType.Password)
              .placeholderColor($r('app.color.text_hint'))
              .fontSize(16)
              .fontColor($r('app.color.text_primary'))
              .backgroundColor($r('app.color.card_bg'))
              .borderRadius(16)
              .padding({ left: 16, right: 16 })

            Row({ space: 8 }) {
              Row() {
                if (this.agreed) {
                  Text('✓')
                    .fontSize(12)
                    .fontColor(Color.White)
                    .fontWeight(FontWeight.Bold)
                }
              }
              .width(18)
              .height(18)
              .borderRadius(4)
              .justifyContent(FlexAlign.Center)
              .border({ width: 1, color: this.agreed ? $r('app.color.primary_color') : $r('app.color.text_hint') })
              .backgroundColor(this.agreed ? $r('app.color.primary_color') : Color.Transparent)
              .onClick(() => { this.agreed = !this.agreed; })

              Text('我已阅读并同意')
                .fontSize(13)
                .fontColor($r('app.color.text_secondary'))
              Text('《用户协议》')
                .fontSize(13)
                .fontColor($r('app.color.primary_color'))
                .onClick(() => this.openTerms())
              Text('和')
                .fontSize(13)
                .fontColor($r('app.color.text_secondary'))
              Text('《隐私政策》')
                .fontSize(13)
                .fontColor($r('app.color.primary_color'))
                .onClick(() => this.openPrivacy())
            }
            .width('100%')
            .margin({ top: 4 })

            Button(this.isSubmitting ? '注册中...' : $r('app.string.register_button'))
              .width('100%')
              .height(52)
              .backgroundColor(this.isSubmitting ? $r('app.color.text_hint') : $r('app.color.primary_color'))
              .borderRadius(16)
              .fontSize(16)
              .fontWeight(FontWeight.Medium)
              .fontColor(Color.White)
              .shadow({ radius: 8, color: 'rgba(74, 127, 255, 0.4)', offsetY: 4 })
              .margin({ top: 8 })
              .enabled(!this.isSubmitting)
              .onClick(() => this.handleRegister())

            Row() {
              Text($r('app.string.register_to_login_prefix'))
                .fontSize(14)
                .fontColor($r('app.color.text_secondary'))
              Text($r('app.string.register_to_login_action'))
                .fontSize(14)
                .fontColor($r('app.color.primary_color'))
                .fontWeight(FontWeight.Medium)
                .onClick(() => this.goToLogin())
            }
            .margin({ top: 16 })
            .width('100%')
          }
          .width('100%')
          .alignItems(HorizontalAlign.Start)
        }
        .width('100%')
        .padding({ left: 24, right: 24 })
        .alignItems(HorizontalAlign.Center)
      }
      .align(Alignment.Top)
      .scrollBar(BarState.Off)
      .edgeEffect(EdgeEffect.Spring)
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.bg_color'))
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
  }
}
