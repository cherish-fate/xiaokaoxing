import {
  apiService,
  ApiResponse,
  VoteListResponse,
  VoteItem,
  SubmitVoteRequest,
  SubmitVoteResponse,
  VoteResultResponse,
  MyVoteListResponse,
  MyVoteRecord,
  MySubmissionsResponse,
  MySubmissionItem,
  PendingSubmission,
  PendingSubmissionsResponse
} from '../api/ApiService';
import {
  VoteListModel,
  VoteItemModel,
  SubmitVoteResultModel,
  VoteResultModel,
  MyVoteListModel,
  MyVoteRecordModel,
  MySubmissionsModel,
  MySubmissionModel,
  PendingSubmissionModel,
  PendingSubmissionListModel
} from '../model/VoteModel';
import { ResultUtil, AsyncResult } from '../utils/ResultUtil';
import { Logger } from '../utils/Logger';
import { DateUtil } from '../utils/DateUtil';

const TAG = 'VoteRepository';

export class VoteRepository {
  private mapVoteItem(v: VoteItem): VoteItemModel {
    return new VoteItemModel(
      v.id,
      v.subject || '',
      v.title || '',
      v.description,
      v.vote_count || 0,
      v.confidence || 0,
      v.stars || 0,
      !!v.has_voted
    );
  }

  private mapMyVoteRecord(r: MyVoteRecord): MyVoteRecordModel {
    return new MyVoteRecordModel(
      r.vote_id,
      r.subject || '',
      r.title || '',
      r.vote_count || 0,
      r.confidence || 0,
      r.voted_at ? DateUtil.toShortDateTime(r.voted_at) : '',
      r.my_choice || '会考'
    );
  }

  private mapMySubmission(s: MySubmissionItem): MySubmissionModel {
    return new MySubmissionModel(
      s.id,
      s.subject || '',
      s.title || '',
      s.description,
      s.status || '',
      s.created_at ? DateUtil.toShortDateTime(s.created_at) : ''
    );
  }

  private mapPendingSubmission(s: PendingSubmission): PendingSubmissionModel {
    return new PendingSubmissionModel(
      s.id,
      s.subject || '',
      s.title || '',
      s.description,
      s.status || '',
      s.created_at ? DateUtil.toShortDateTime(s.created_at) : '',
      s.author_name || '',
      s.author_avatar || null
    );
  }

  async loadVotes(subject?: string): Promise<AsyncResult<VoteListModel>> {
    const res: ApiResponse<VoteListResponse> = await apiService.fetchVotes(subject);
    if (res.code === 401) {
      return ResultUtil.fail<VoteListModel>(401, res.message || '登录已过期');
    }
    if (res.code !== 200 || !res.data) {
      return ResultUtil.fail<VoteListModel>(res.code, res.message || '投票列表加载失败');
    }
    const list: VoteItemModel[] = (res.data.list || []).map(v => this.mapVoteItem(v));
    return ResultUtil.success(new VoteListModel(list));
  }

  async submitVotePoint(req: SubmitVoteRequest): Promise<AsyncResult<SubmitVoteResultModel>> {
    if (!req.subject) {
      return ResultUtil.fail<SubmitVoteResultModel>(400, '请选择科目');
    }
    if (!req.title || req.title.trim().length === 0) {
      return ResultUtil.fail<SubmitVoteResultModel>(400, '考点名称不能为空');
    }
    if (req.title.length > 30) {
      return ResultUtil.fail<SubmitVoteResultModel>(400, '考点名称不能超过30字');
    }
    const body: SubmitVoteRequest = {
      subject: req.subject,
      title: req.title.trim(),
      description: req.description && req.description.length > 200
        ? req.description.substring(0, 200) : req.description
    };
    const res: ApiResponse<SubmitVoteResponse> = await apiService.submitVote(body);
    if (res.code === 401) {
      return ResultUtil.fail<SubmitVoteResultModel>(401, res.message || '登录已过期');
    }
    if ((res.code !== 200 && res.code !== 201) || !res.data) {
      return ResultUtil.fail<SubmitVoteResultModel>(res.code, res.message || '考点提交失败');
    }
    const result = new SubmitVoteResultModel(
      res.data.id,
      res.data.subject,
      res.data.title,
      res.data.status,
      res.data.created_at ? DateUtil.toShortDateTime(res.data.created_at) : '',
      res.message || '考点提交成功'
    );
    Logger.info(TAG, `考点提交成功: ${result.id}`);
    return ResultUtil.success(result);
  }

  async voteFor(voteId: number): Promise<AsyncResult<VoteResultModel>> {
    const res: ApiResponse<VoteResultResponse> = await apiService.voteFor(voteId);
    if (res.code === 401) {
      return ResultUtil.fail<VoteResultModel>(401, res.message || '登录已过期');
    }
    if (res.code === 409) {
      return ResultUtil.fail<VoteResultModel>(409, res.message || '您已投过该考点，不可重复投票');
    }
    if (res.code !== 200 || !res.data) {
      return ResultUtil.fail<VoteResultModel>(res.code, res.message || '投票失败');
    }
    return ResultUtil.success(new VoteResultModel(
      res.data.vote_id,
      res.data.vote_count,
      res.data.confidence
    ));
  }

  async loadMyVotes(): Promise<AsyncResult<MyVoteListModel>> {
    const res: ApiResponse<MyVoteListResponse> = await apiService.fetchMyVotes();
    if (res.code === 401) {
      return ResultUtil.fail<MyVoteListModel>(401, res.message || '登录已过期');
    }
    if (res.code !== 200 || !res.data) {
      return ResultUtil.fail<MyVoteListModel>(res.code, res.message || '我的投票记录加载失败');
    }
    const list = (res.data.list || []).map(r => this.mapMyVoteRecord(r));
    return ResultUtil.success(new MyVoteListModel(list));
  }

  async loadMySubmissions(): Promise<AsyncResult<MySubmissionsModel>> {
    const res: ApiResponse<MySubmissionsResponse> = await apiService.fetchMySubmissions();
    if (res.code === 401) {
      return ResultUtil.fail<MySubmissionsModel>(401, res.message || '登录已过期');
    }
    if (res.code !== 200 || !res.data) {
      return ResultUtil.fail<MySubmissionsModel>(res.code, res.message || '我提交的考点加载失败');
    }
    const list = (res.data.list || []).map(s => this.mapMySubmission(s));
    return ResultUtil.success(new MySubmissionsModel(list));
  }

  async loadPendingSubmissions(): Promise<AsyncResult<PendingSubmissionListModel>> {
    const res: ApiResponse<PendingSubmissionsResponse> = await apiService.fetchPendingSubmissions();
    if (res.code === 401) {
      return ResultUtil.fail<PendingSubmissionListModel>(401, res.message || '登录已过期');
    }
    if (res.code !== 200 || !res.data) {
      return ResultUtil.fail<PendingSubmissionListModel>(res.code, res.message || '待审核考点加载失败');
    }
    const list = (res.data.list || []).map(s => this.mapPendingSubmission(s));
    return ResultUtil.success(new PendingSubmissionListModel(list));
  }
}

export const voteRepository: VoteRepository = new VoteRepository();
