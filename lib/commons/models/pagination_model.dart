class Pagination {
  dynamic currentPage;
  dynamic lastPage;
  dynamic perPage;
  dynamic total;
  dynamic count;
  dynamic hasNext;
  dynamic paginationName;

  Pagination(
      {this.currentPage,
      this.lastPage,
      this.perPage,
      this.total,
      this.count,
      this.hasNext,
      this.paginationName,
      });

  Pagination.fromJson(Map<String, dynamic> json) {
    currentPage = json['current_page'];

    lastPage = json['last_page'];
    perPage = json['per_page'];

    total = json['total'];
    count = json['count'];
    hasNext = json['has_next'];

    paginationName = json['pagination_name'];
  }
}
