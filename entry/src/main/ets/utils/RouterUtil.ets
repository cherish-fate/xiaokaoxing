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

  static pushToSearch(): void {
    RouterUtil.pushWithParams(RouteUrls.SEARCH, {});
  }

  static pushToAiChat(initialMessage: string = '', autoSend: boolean = false): void {
    const params: Record<string, Object> = {};
    params['initialMessage'] = initialMessage || '';
    params['autoSend'] = autoSend ? '1' : '0';
    RouterUtil.pushWithParams(RouteUrls.AI_CHAT, params);
  }

  static pushToResourceDetail(id: number, params: string): void {
    const p: Record<string, Object> = {};
    p['id'] = String(id);
    p['params'] = params;
    RouterUtil.pushWithParams(RouteUrls.RESOURCE_DETAIL, p);
  }

  static pushToResourceList(category: string = ''): void {
    const p: Record<string, Object> = {};
    p['category'] = category;
    RouterUtil.pushWithParams(RouteUrls.RESOURCE_LIST, p);
  }
}
