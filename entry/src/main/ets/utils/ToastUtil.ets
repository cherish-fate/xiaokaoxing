import { promptAction } from '@kit.ArkUI';

export class ToastUtil {
  static show(msg: string, duration: number = 2000): void {
    try {
      promptAction.showToast({ message: msg, duration: duration });
    } catch (e) {
      console.error('ToastUtil.show error:', JSON.stringify(e));
    }
  }
}
