import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import '../models/lesson_model.dart';

class PhotoViewScreen extends StatefulWidget {
  final List<LessonPhoto> photos;
  final int initialIndex;

  const PhotoViewScreen({
    super.key,
    required this.photos,
    required this.initialIndex,
  });

  @override
  State<PhotoViewScreen> createState() => _PhotoViewScreenState();
}

class _PhotoViewScreenState extends State<PhotoViewScreen> {
  late int currentIndex;
  late PageController pageController;

  @override
  void initState() {
    super.initState();
    currentIndex = widget.initialIndex;
    pageController = PageController(initialPage: currentIndex);
  }

  @override
  void dispose() {
    pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          '${currentIndex + 1} / ${widget.photos.length}',
          style: const TextStyle(color: Colors.white),
        ),
      ),
      body: PhotoViewGallery.builder(
        scrollPhysics: const BouncingScrollPhysics(),
        builder: (BuildContext context, int index) {
          return PhotoViewGalleryPageOptions(
            imageProvider: NetworkImage(widget.photos[index].url),
            initialScale: PhotoViewComputedScale.contained,
            minScale: PhotoViewComputedScale.contained,
            maxScale: PhotoViewComputedScale.covered * 2,
            heroAttributes: PhotoViewHeroAttributes(tag: 'photo_${widget.photos[index].id}'),
          );
        },
        itemCount: widget.photos.length,
        loadingBuilder: (context, event) => Center(
          child: SizedBox(
            width: 20.0,
            height: 20.0,
            child: CircularProgressIndicator(
              value: event == null
                  ? 0
                  : event.cumulativeBytesLoaded / event.expectedTotalBytes!,
            ),
          ),
        ),
        backgroundDecoration: const BoxDecoration(color: Colors.black),
        pageController: pageController,
        onPageChanged: (index) {
          setState(() {
            currentIndex = index;
          });
          
          // 显示照片描述
          if (mounted) {
            ScaffoldMessenger.of(context).removeCurrentSnackBar();
            if (widget.photos[index].description?.isNotEmpty == true) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(widget.photos[index].description!),
                  duration: const Duration(seconds: 2),
                ),
              );
            }
          }
        },
      ),
    );
  }
} 