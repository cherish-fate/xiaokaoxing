export class ResourceModel {
  id: number;
  title: string;
  typeTag: string;
  description: string;
  fileUrl: string;

  constructor(id: number, title: string, typeTag: string, description: string, fileUrl: string) {
    this.id = id;
    this.title = title;
    this.typeTag = typeTag;
    this.description = description;
    this.fileUrl = fileUrl;
  }

  tagColor(): string {
    if (this.typeTag.indexOf('本校') >= 0) {
      return '#E8F0FF';
    }
    if (this.typeTag.indexOf('高频') >= 0 || this.typeTag.indexOf('必考') >= 0) {
      return '#FFF3E8';
    }
    return '#E6F7F5';
  }

  tagTextColor(): string {
    if (this.typeTag.indexOf('本校') >= 0) {
      return '#4A7FFF';
    }
    if (this.typeTag.indexOf('高频') >= 0 || this.typeTag.indexOf('必考') >= 0) {
      return '#FF7E02';
    }
    return '#38CFC9';
  }
}
