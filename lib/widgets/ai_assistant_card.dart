import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:teman_keluarga/app/theme/app_theme.dart';
// Import Controller yang baru diperbaiki
import 'package:teman_keluarga/features/medication/presentation/gemini_live_controller.dart';

class AiAssistantCard extends ConsumerWidget {
  const AiAssistantCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Pantau status: Apakah sedang ngobrol?
    final isLive = ref.watch(isLiveSessionActiveProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            "Tanya AI",
            style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            // Ubah warna background sedikit saat aktif agar user sadar
            color: isLive
                ? Colors.red.withOpacity(0.1)
                : AppColors.secondary.withOpacity(0.56),
            borderRadius: BorderRadius.circular(16),
            border: isLive ? Border.all(color: Colors.red, width: 2) : null,
          ),
          child: Column(
            children: [
              if (isLive)
                const Padding(
                  padding: EdgeInsets.only(bottom: 16.0),
                  child: Text(
                    "Sedang Mendengarkan... (Bicara Saja)",
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

              // Mic Button (Besar untuk Lansia)
              GestureDetector(
                onTap: () {
                  if (isLive) {
                    ref.read(geminiLiveControllerProvider).stopSession();
                  } else {
                    ref.read(geminiLiveControllerProvider).startSession();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Menghubungkan ke Gemini Live..."),
                      ),
                    );
                  }
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: isLive ? Colors.red : AppColors.surface,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: isLive
                            ? Colors.red.withOpacity(0.4)
                            : AppColors.primary.withOpacity(0.1),
                        blurRadius: 12,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Icon(
                    isLive ? Icons.stop : Icons.mic, // Ikon berubah
                    size: 32, // Sedikit diperbesar
                    color: isLive ? Colors.white : AppColors.primary,
                  ),
                ),
              ),

              // const SizedBox(height: 24),

              // // Input & Send (Placeholder Visual dulu sesuai request)
              // Row(
              //   children: [
              //     Expanded(
              //       child: Container(
              //         padding: const EdgeInsets.symmetric(horizontal: 16),
              //         decoration: BoxDecoration(
              //           color: AppColors.surface,
              //           borderRadius: BorderRadius.circular(16),
              //         ),
              //         child: const TextField(
              //           decoration: InputDecoration(
              //             hintText: "Tanya sesuatu...",
              //             border: InputBorder.none,
              //             hintStyle: TextStyle(fontSize: 14),
              //           ),
              //         ),
              //       ),
              //     ),
              //     const SizedBox(width: 8),
              //     Container(
              //       decoration: BoxDecoration(
              //         color: AppColors.primary,
              //         borderRadius: BorderRadius.circular(16),
              //       ),
              //       child: IconButton(
              //         onPressed: () {
              //           ScaffoldMessenger.of(context).showSnackBar(
              //             const SnackBar(
              //               content: Text("Fitur teks akan segera hadir"),
              //             ),
              //           );
              //         },
              //         icon: const Icon(Icons.send, color: AppColors.surface),
              //       ),
              //     ),
              //   ],
              // ),
            ],
          ),
        ),
      ],
    );
  }
}
