import {
  apiService,
  ApiResponse,
  BookmarkListResponse,
  BookmarkItem,
  CreateBookmarkRequest,
  CreateBookmarkResponse,
  UpdateBookmarkRequest,
  UpdateBookmarkResponse
} from '../api/ApiService';
import { BookmarkItemModel, BookmarkListModel } from '../model/BookmarkModel';
import { ResultUtil, AsyncResult } from '../utils/ResultUtil';
import { Logger } from '../utils/Logger';

const TAG: string = 'BookmarkRepository';

interface BookmarkUpdateResult {
  id: number;
  note: string;
  color: string;
}

export class BookmarkRepository {
  async loadBookmarks(
    color: string | null = null,
    keyword: string | null = null
  ): Promise<AsyncResult<BookmarkListModel>> {
    const res: ApiResponse<BookmarkListResponse> = await apiService.fetchBookmarks(color, keyword);
    if (res.code === 401) {
      return ResultUtil.fail<BookmarkListModel>(401, res.message || '登录已过期');
    }
    if (res.code !== 200 || !res.data) {
      return ResultUtil.fail<BookmarkListModel>(res.code, res.message || '获取书签列表失败');
    }
    try {
      const list: BookmarkItemModel[] = (res.data.list || []).map(b => BookmarkItemModel.fromApi(b));
      const total: number = res.data.total || 0;
      Logger.info(TAG, `书签列表加载成功，共${total}条`);
      return ResultUtil.success(BookmarkListModel.fromTotalAndList(total, list));
    } catch (e) {
      Logger.error(TAG, '书签列表数据转换失败', e as Error);
      return ResultUtil.fail<BookmarkListModel>(500, '数据解析失败');
    }
  }

  async createBookmark(
    quote: string,
    sourceTitle: string,
    sourceType: string,
    sourceUrl: string = '',
    sourceId: number = 0,
    note: string = '',
    color: string = 'yellow'
  ): Promise<AsyncResult<BookmarkItemModel>> {
    const req: CreateBookmarkRequest = {
      quote: quote,
      source_title: sourceTitle,
      source_type: sourceType,
      color: color
    };
    if (sourceUrl.length > 0) {
      req.source_url = sourceUrl;
    }
    if (sourceId > 0) {
      req.source_id = sourceId;
    }
    if (note.length > 0) {
      req.note = note;
    }
    const res: ApiResponse<CreateBookmarkResponse> = await apiService.createBookmark(req);
    if (res.code === 401) {
      return ResultUtil.fail<BookmarkItemModel>(401, res.message || '登录已过期');
    }
    if (res.code !== 201 || !res.data) {
      return ResultUtil.fail<BookmarkItemModel>(res.code, res.message || '书签添加失败');
    }
    Logger.info(TAG, `书签创建成功 id=${res.data.id}`);
    const item: BookmarkItemModel = new BookmarkItemModel(
      res.data.id || 0,
      quote,
      sourceTitle,
      sourceUrl,
      sourceType,
      sourceId,
      note,
      res.data.color || color,
      res.data.created_at || ''
    );
    return ResultUtil.success(item);
  }

  async updateBookmark(
    id: number,
    note: string | null = null,
    color: string | null = null
  ): Promise<AsyncResult<BookmarkUpdateResult>> {
    const req: UpdateBookmarkRequest = {};
    if (note !== null) req.note = note;
    if (color !== null) req.color = color;
    const res: ApiResponse<UpdateBookmarkResponse> = await apiService.updateBookmark(id, req);
    if (res.code === 401) {
      return ResultUtil.fail<BookmarkUpdateResult>(401, res.message || '登录已过期');
    }
    if (res.code !== 200 || !res.data) {
      return ResultUtil.fail<BookmarkUpdateResult>(res.code, res.message || '书签更新失败');
    }
    Logger.info(TAG, `书签${id}更新成功`);
    const result: BookmarkUpdateResult = {
      id: res.data.id || id,
      note: res.data.note || '',
      color: res.data.color || 'yellow'
    };
    return ResultUtil.success(result);
  }

  async deleteBookmark(id: number): Promise<AsyncResult<null>> {
    const res: ApiResponse<null> = await apiService.deleteBookmark(id);
    if (res.code === 401) {
      return ResultUtil.fail<null>(401, res.message || '登录已过期');
    }
    if (res.code !== 200) {
      return ResultUtil.fail<null>(res.code, res.message || '删除书签失败');
    }
    Logger.info(TAG, `书签${id}删除成功`);
    return ResultUtil.success(null);
  }
}

export const bookmarkRepository: BookmarkRepository = new BookmarkRepository();
