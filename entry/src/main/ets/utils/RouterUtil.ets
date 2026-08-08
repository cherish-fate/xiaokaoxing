import { router } from '@kit.ArkUI';
import { RouteUrls } from './RouteUrls';
import { Logger } from './Logger';

const TAG = 'RouterUtil';

export class RouterUtil {
  static push(url: string, params?: Record<string, Object>): void {
    try {
      if (params) {
        const paramsStr = Object.keys(params).map(k => `${k}=${params![k]}`).join('&');
        router.pushUrl({ url: `${url}?${paramsStr}` });
      } else {
        router.pushUrl({ url });
      }
    } catch (e) {
      Logger.error(TAG, `push ${url} failed`, e as Error);
    }
  }

  static pushWithParams(url: string, params: Record<string, Object>): void {
    try {
      router.pushUrl({ url: url, params: params });
    } catch (e) {
      Logger.error(TAG, `pushWithParams ${url} failed`, e as Error);
    }
  }

  static replace(url: string): void {
    try {
      router.replaceUrl({ url });
    } catch (e) {
      Logger.error(TAG, `replace ${url} failed`, e as Error);
    }
  }

  static back(): void {
    try {
      router.back();
    } catch (e) {
      Logger.error(TAG, 'back failed', e as Error);
    }
  }

  static toLogin(): void {
    RouterUtil.replace(RouteUrls.LOGIN);
  }

  static toHome(): void {
    RouterUtil.replace(RouteUrls.HOME);
  }
}
