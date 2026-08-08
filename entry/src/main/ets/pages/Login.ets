import { promptAction, router } from '@kit.ArkUI';
import { apiService, LoginRequest } from '../api/ApiService';

@Entry
@Component
struct LoginPage {
  @State email: string = '';
  @State password: string = '';
  @State isSubmitting: boolean = false;

  private showToast(message: Resource | string): void {
    promptAction.showToast({ message, duration: 2000 });
  }

  private isValidEmail(email: string): boolean {
    const regExp = /^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$/;
    return regExp.test(email);
  }

  private async handleLogin(): Promise<void> {
    if (this.isSubmitting) {
      return;
    }

    if (this.email.trim().length === 0) {
      this.showToast('请输入邮箱');
      return;
    }
    if (!this.isValidEmail(this.email.trim())) {
      this.showToast('邮箱格式不正确');
      return;
    }
    if (this.password.length === 0) {
      this.showToast('请输入密码');
      return;
    }

    this.isSubmitting = true;

    const req: LoginRequest = {
      email: this.email.trim(),
      password: this.password
    };

    try {
      const res = await apiService.login(req);
      if (res.code === 200 && res.data) {
        await apiService.saveToken(res.data.token);
        this.showToast('登录成功');
        setTimeout(() => {
          router.replaceUrl({ url: 'pages/HomePage' });
        }, 1000);
      } else if (res.code === 400) {
        this.showToast(res.message || '请求参数错误');
      } else if (res.code === 401) {
        this.showToast(res.message || '密码错误，请重新输入');
      } else if (res.code === 404) {
        this.showToast(res.message || '该邮箱未注册，请先注册');
      } else {
        this.showToast(res.message || '登录失败，请重试');
      }
    } catch (e) {
      this.showToast('网络请求失败，请稍后重试');
    } finally {
      this.isSubmitting = false;
    }
  }

  private goToRegister(): void {
    router.replaceUrl({ url: 'pages/RegisterPage' });
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
            Text($r('app.string.login_title'))
              .fontSize(24)
              .fontWeight(FontWeight.Bold)
              .fontColor($r('app.color.text_primary'))
              .width('100%')

            TextInput({ placeholder: $r('app.string.login_email_hint'), text: $$this.email })
              .width('100%')
              .height(52)
              .type(InputType.Email)
              .placeholderColor($r('app.color.text_hint'))
              .fontSize(16)
              .fontColor($r('app.color.text_primary'))
              .backgroundColor($r('app.color.card_bg'))
              .borderRadius(16)
              .padding({ left: 16, right: 16 })

            TextInput({ placeholder: $r('app.string.login_password_hint'), text: $$this.password })
              .width('100%')
              .height(52)
              .type(InputType.Password)
              .placeholderColor($r('app.color.text_hint'))
              .fontSize(16)
              .fontColor($r('app.color.text_primary'))
              .backgroundColor($r('app.color.card_bg'))
              .borderRadius(16)
              .padding({ left: 16, right: 16 })

            Button(this.isSubmitting ? '登录中...' : $r('app.string.login_button'))
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
              .onClick(() => this.handleLogin())

            Row() {
              Text($r('app.string.login_to_register_prefix'))
                .fontSize(14)
                .fontColor($r('app.color.text_secondary'))
              Text($r('app.string.login_to_register_action'))
                .fontSize(14)
                .fontColor($r('app.color.primary_color'))
                .fontWeight(FontWeight.Medium)
                .onClick(() => this.goToRegister())
            }
            .margin({ top: 16 })
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
