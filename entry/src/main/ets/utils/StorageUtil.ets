import preferences from '@ohos.data.preferences';
import { Logger } from './Logger';

const TAG = 'StorageUtil';
const PREF_NAME = 'user_prefs';

export class StorageUtil {
  private static async getPref(): Promise<preferences.Preferences> {
    return await preferences.getPreferences(getContext(), PREF_NAME);
  }

  static async put(key: string, value: string | number | boolean): Promise<void> {
    try {
      const pref = await StorageUtil.getPref();
      await pref.put(key, value);
      await pref.flush();
    } catch (e) {
      Logger.error(TAG, `put ${key} failed`, e as Error);
    }
  }

  static async getString(key: string, def: string = ''): Promise<string> {
    try {
      const pref = await StorageUtil.getPref();
      return (await pref.get(key, def)) as string;
    } catch (e) {
      return def;
    }
  }

  static async getNumber(key: string, def: number = 0): Promise<number> {
    try {
      const pref = await StorageUtil.getPref();
      return (await pref.get(key, def)) as number;
    } catch (e) {
      return def;
    }
  }

  static async getBoolean(key: string, def: boolean = false): Promise<boolean> {
    try {
      const pref = await StorageUtil.getPref();
      return (await pref.get(key, def)) as boolean;
    } catch (e) {
      return def;
    }
  }

  static async remove(key: string): Promise<void> {
    try {
      const pref = await StorageUtil.getPref();
      await pref.delete(key);
      await pref.flush();
    } catch (e) {
      Logger.error(TAG, `remove ${key} failed`, e as Error);
    }
  }

  static clearToken(): Promise<void> {
    return StorageUtil.remove('token');
  }
}
