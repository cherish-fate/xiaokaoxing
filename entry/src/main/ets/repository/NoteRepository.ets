import {
  apiService,
  ApiResponse,
  NoteListResponse,
  NoteDetailResponse,
  CreateNoteRequest,
  UpdateNoteRequest,
  UpdateNoteResponse,
  TogglePinResponse
} from '../api/ApiService';
import {
  NoteListModel,
  NoteDetailModel
} from '../model/NoteModel';
import { ResultUtil, AsyncResult } from '../utils/ResultUtil';
import { Logger } from '../utils/Logger';

const TAG: string = 'NoteRepository';

interface GeneratedTypeLiteralInterface_1 {
  id: number;
  updatedAt: string;
}

export class NoteRepository {
  async loadNotes(
    tag: string | null = null,
    keyword: string | null = null,
    limit: number = 20,
    offset: number = 0
  ): Promise<AsyncResult<NoteListModel>> {
    const res: ApiResponse<NoteListResponse> = await apiService.fetchNotes(tag, keyword, limit, offset);
    if (res.code === 401) {
      return ResultUtil.fail<NoteListModel>(401, res.message || '登录已过期');
    }
    if (res.code !== 200 || !res.data) {
      return ResultUtil.fail<NoteListModel>(res.code, res.message || '获取笔记失败');
    }
    try {
      const model: NoteListModel = NoteListModel.fromApi(res.data);
      Logger.info(TAG, '笔记列表加载成功');
      return ResultUtil.success(model);
    } catch (e) {
      Logger.error(TAG, '笔记列表数据转换失败', e as Error);
      return ResultUtil.fail<NoteListModel>(500, '数据解析失败');
    }
  }

  async loadNoteDetail(id: number): Promise<AsyncResult<NoteDetailModel>> {
    const res: ApiResponse<NoteDetailResponse> = await apiService.fetchNoteDetail(id);
    if (res.code === 401) {
      return ResultUtil.fail<NoteDetailModel>(401, res.message || '登录已过期');
    }
    if (res.code !== 200 || !res.data) {
      return ResultUtil.fail<NoteDetailModel>(res.code, res.message || '获取笔记详情失败');
    }
    try {
      const model: NoteDetailModel = NoteDetailModel.fromApi(res.data);
      Logger.info(TAG, '笔记详情加载成功');
      return ResultUtil.success(model);
    } catch (e) {
      Logger.error(TAG, '笔记详情数据转换失败', e as Error);
      return ResultUtil.fail<NoteDetailModel>(500, '数据解析失败');
    }
  }

  async createNote(
    title: string,
    content: string,
    tags: string[]
  ): Promise<AsyncResult<NoteDetailModel>> {
    const req: CreateNoteRequest = { title, content, tags };
    const res: ApiResponse<NoteDetailResponse> = await apiService.createNote(req);
    if (res.code === 401) {
      return ResultUtil.fail<NoteDetailModel>(401, res.message || '登录已过期');
    }
    if (res.code !== 201 || !res.data) {
      return ResultUtil.fail<NoteDetailModel>(res.code, res.message || '创建笔记失败');
    }
    try {
      const model: NoteDetailModel = NoteDetailModel.fromApi(res.data);
      Logger.info(TAG, '笔记创建成功');
      return ResultUtil.success(model);
    } catch (e) {
      Logger.error(TAG, '笔记数据转换失败', e as Error);
      return ResultUtil.fail<NoteDetailModel>(500, '数据解析失败');
    }
  }

  async updateNote(
    id: number,
    title: string,
    content: string,
    tags: string[]
  ): Promise<AsyncResult<GeneratedTypeLiteralInterface_1>> {
    const req: UpdateNoteRequest = { title, content, tags };
    const res: ApiResponse<UpdateNoteResponse> = await apiService.updateNote(id, req);
    if (res.code === 401) {
      return ResultUtil.fail<GeneratedTypeLiteralInterface_1>(401, res.message || '登录已过期');
    }
    if (res.code !== 200 || !res.data) {
      return ResultUtil.fail<GeneratedTypeLiteralInterface_1>(res.code, res.message || '保存笔记失败');
    }
    Logger.info(TAG, '笔记更新成功');
    const result:GeneratedTypeLiteralInterface_1={
      id: res.data.id || id,
      updatedAt: res.data.updated_at || ''
    }
    return ResultUtil.success(result);
  }

  async deleteNote(id: number): Promise<AsyncResult<null>> {
    const res: ApiResponse<null> = await apiService.deleteNote(id);
    if (res.code === 401) {
      return ResultUtil.fail<null>(401, res.message || '登录已过期');
    }
    if (res.code !== 200) {
      return ResultUtil.fail<null>(res.code, res.message || '删除笔记失败');
    }
    Logger.info(TAG, '笔记删除成功');
    return ResultUtil.success(null);
  }

  async togglePin(id: number, isPinned: boolean): Promise<AsyncResult<boolean>> {
    const res: ApiResponse<TogglePinResponse> = await apiService.toggleNotePin(id, isPinned);
    if (res.code === 401) {
      return ResultUtil.fail<boolean>(401, res.message || '登录已过期');
    }
    if (res.code !== 200 || !res.data) {
      return ResultUtil.fail<boolean>(res.code, res.message || '操作失败');
    }
    Logger.info(TAG, '置顶状态更新成功');
    return ResultUtil.success(!!res.data.is_pinned);
  }
}

export const noteRepository: NoteRepository = new NoteRepository();
