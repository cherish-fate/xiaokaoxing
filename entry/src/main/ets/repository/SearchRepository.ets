import { apiService, ApiResponse, ResourceListResponse, ResourceItem } from '../api/ApiService';
import { PrepResourceItemModel } from '../model/PrepModel';
import { ResultUtil, AsyncResult } from '../utils/ResultUtil';
import { Logger } from '../utils/Logger';
import { StorageUtil } from '../utils/StorageUtil';

const TAG = 'SearchRepository';
const SEARCH_HISTORY_KEY = 'search_history';
const MAX_HISTORY = 10;

export interface SearchResult {
  list: PrepResourceItemModel[];
  total: number;
  keyword: string;
}

export class SearchRepository {
  private mapResource(item: ResourceItem): PrepResourceItemModel {
    let shortDate = '';
    if (item.created_at && item.created_at.length >= 10) {
      shortDate = item.created_at.substring(2);
    } else if (item.created_at) {
      shortDate = item.created_at;
    }
    return new PrepResourceItemModel(
      item.id,
      item.title || '',
      item.category || '',
      item.type_tag || '',
      !!item.is_hot,
      item.author || '',
      shortDate,
      item.view_count || 0,
      !!item.is_favorited,
      item.file_url || ''
    );
  }

  async search(
    keyword: string,
    limit: number = 10,
    offset: number = 0
  ): Promise<AsyncResult<SearchResult>> {
    const res: ApiResponse<ResourceListResponse> = await apiService.searchResources(keyword, limit, offset);
    if (res.code === 401) {
      return ResultUtil.fail(401, res.message || '登录已过期');
    }
    if (res.code === 400) {
      return ResultUtil.fail(400, res.message || '关键词不能为空');
    }
    if (res.code !== 200 || !res.data) {
      return ResultUtil.fail(res.code, res.message || '搜索失败');
    }
    const list: PrepResourceItemModel[] = (res.data.list || []).map((r: ResourceItem) => this.mapResource(r));
    const total: number = res.data.total || list.length;
    const kw: string = res.data.keyword || keyword;
    const result: SearchResult = {
      list: list,
      total: total,
      keyword: kw
    };

    Logger.info(TAG, `搜索 ${kw} 结果 ${list.length} 条`);
    return ResultUtil.success(result);
  }

  async getSearchHistory(): Promise<string[]> {
    const raw: string = await StorageUtil.getString(SEARCH_HISTORY_KEY, '');
    if (!raw) return [];
    try {
      const parsed: Object = JSON.parse(raw) as Object;
      if (parsed instanceof Array) {
        const arr: string[] = [];
        for (let i = 0; i < parsed.length; i++) {
          const v:Object = parsed[i];
          if (typeof v === 'string') arr.push(v as string);
        }
        return arr.slice(0, MAX_HISTORY);
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  async addSearchHistory(keyword: string): Promise<void> {
    if (!keyword || !keyword.trim()) return;
    const kw: string = keyword.trim();
    let history: string[] = await this.getSearchHistory();
    history = history.filter(h => h !== kw);
    history.unshift(kw);
    if (history.length > MAX_HISTORY) history = history.slice(0, MAX_HISTORY);
    await StorageUtil.put(SEARCH_HISTORY_KEY, JSON.stringify(history));
  }

  async clearSearchHistory(): Promise<void> {
    await StorageUtil.remove(SEARCH_HISTORY_KEY);
  }
}

export const searchRepository: SearchRepository = new SearchRepository();
