import { promptAction, router } from '@kit.ArkUI';

@Entry
@Component
struct LoginPage {
  @State email: string = '';
  @State password: string = '';

  private showToast(message: Resource | string): void {
    promptAction.showToast({ message, duration: 2000 });
  }

  private handleLogin(): void {
    if (this.email.trim().length === 0) {
      this.showToast($r('app.string.register_email_empty'));
      return;
    }
    if (this.password.length === 0) {
      this.showToast('请输入密码');
      return;
    }

    // TODO: 调用登录接口，完成后跳转首页
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

            Button($r('app.string.login_button'))
              .width('100%')
              .height(52)
              .backgroundColor($r('app.color.primary_color'))
              .borderRadius(16)
              .fontSize(16)
              .fontWeight(FontWeight.Medium)
              .fontColor(Color.White)
              .shadow({ radius: 8, color: 'rgba(74, 127, 255, 0.4)', offsetY: 4 })
              .margin({ top: 8 })
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
