import 'package:flutter/material.dart';

class SearchTab extends StatefulWidget {
  const SearchTab({super.key});

  @override
  State<SearchTab> createState() => _SearchTabState();
}

class _SearchTabState extends State<SearchTab> {
  final _searchController = TextEditingController();
  final _focusNode = FocusNode();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          // 검색바
          Container(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              focusNode: _focusNode,
              decoration: InputDecoration(
                hintText: '검색어를 입력하세요',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            _searchController.clear();
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                filled: true,
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
          
          // 검색 결과
          Expanded(
            child: _buildSearchResults(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_searchQuery.isEmpty) {
      return _buildEmptyState();
    }

    return _buildSearchResultsList();
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            '검색어를 입력해보세요',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResultsList() {
    // 임시 검색 결과
    final results = List.generate(
      5,
      (index) => {
        'title': '검색 결과 ${index + 1}',
        'subtitle': '검색어 "$_searchQuery"에 대한 결과입니다',
      },
    );

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: results.length,
      itemBuilder: (context, index) {
        final result = results[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              child: Text('${index + 1}'),
            ),
            title: Text(result['title']!),
            subtitle: Text(result['subtitle']!),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
            },
          ),
        );
      },
    );
  }
}