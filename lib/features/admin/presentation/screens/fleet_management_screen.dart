import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/helpers.dart';
import '../../../../core/services/storage_service.dart';
import '../../../cars/presentation/providers/cars_provider.dart';
import '../../../cars/domain/car_entity.dart';

class FleetManagementScreen extends ConsumerWidget {
  const FleetManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final carsAsync = ref.watch(carsListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Fleet Management / CRUD'),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        onPressed: () {
          _showCarFormDialog(context, ref);
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: carsAsync.when(
        data: (cars) {
          if (cars.isEmpty) {
            return const Center(child: Text('No vehicles registered. Press + to add.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: cars.length,
            itemBuilder: (context, index) {
              final car = cars[index];

              return Card(
                elevation: 0,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  side: BorderSide(color: Colors.grey.shade200),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: ListTile(
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: car.images.isNotEmpty
                        ? Image.network(
                            car.images.first,
                            width: 70,
                            height: 45,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Container(
                              color: Colors.grey.shade200,
                              width: 70,
                              height: 45,
                              child: const Icon(Icons.broken_image, size: 20, color: Colors.grey),
                            ),
                          )
                        : Container(color: Colors.grey, width: 70, height: 45),
                  ),
                  title: Text('${car.brand} ${car.model} (${car.year})', style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Plate: ${car.plateNumber} | ${car.locationName}', style: const TextStyle(fontSize: 11)),
                      Text('\$${car.pricePerDay.toInt()}/day', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 12)),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_rounded, color: AppColors.secondary, size: 20),
                        onPressed: () {
                          _showCarFormDialog(context, ref, car: car);
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_forever_rounded, color: AppColors.cancelled, size: 20),
                        onPressed: () {
                          _showDeleteConfirm(context, ref, car);
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
        error: (e, st) => Center(child: Text('Error: ${e.toString()}')),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
    );
  }

  void _showCarFormDialog(BuildContext context, WidgetRef ref, {CarEntity? car}) {
    final formKey = GlobalKey<FormState>();
    final brandController = TextEditingController(text: car?.brand ?? '');
    final modelController = TextEditingController(text: car?.model ?? '');
    final yearController = TextEditingController(text: car?.year.toString() ?? '');
    final colorController = TextEditingController(text: car?.color ?? '');
    final plateController = TextEditingController(text: car?.plateNumber ?? '');
    final priceController = TextEditingController(text: car?.pricePerDay.toString() ?? '');
    final locationController = TextEditingController(text: car?.locationName ?? 'Jigjiga Yar, Hargeisa');

    CarCategory selectedCategory = car?.category ?? CarCategory.sedan;
    String? currentImageUrl = car?.images.isNotEmpty == true ? car?.images.first : null;
    bool isUploadingImage = false;

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setState) {
          final isDark = Theme.of(context).brightness == Brightness.dark;

          return AlertDialog(
            title: Text(car == null ? 'Add Vehicle' : 'Edit Vehicle'),
            content: SizedBox(
              width: 400,
              child: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      DropdownButtonFormField<CarCategory>(
                        initialValue: selectedCategory,
                        decoration: const InputDecoration(labelText: 'Category'),
                        items: CarCategory.values.map((cat) {
                          return DropdownMenuItem(value: cat, child: Text(cat.name.toUpperCase()));
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) selectedCategory = val;
                        },
                      ),
                      TextFormField(
                        controller: brandController,
                        decoration: const InputDecoration(labelText: 'Brand (e.g. Toyota)'),
                        validator: (val) => val?.isEmpty == true ? 'Required' : null,
                      ),
                      TextFormField(
                        controller: modelController,
                        decoration: const InputDecoration(labelText: 'Model (e.g. Hilux)'),
                        validator: (val) => val?.isEmpty == true ? 'Required' : null,
                      ),
                      TextFormField(
                        controller: yearController,
                        decoration: const InputDecoration(labelText: 'Year'),
                        keyboardType: TextInputType.number,
                        validator: (val) => val?.isEmpty == true ? 'Required' : null,
                      ),
                      TextFormField(
                        controller: colorController,
                        decoration: const InputDecoration(labelText: 'Color'),
                        validator: (val) => val?.isEmpty == true ? 'Required' : null,
                      ),
                      TextFormField(
                        controller: plateController,
                        decoration: const InputDecoration(labelText: 'Plate Number (e.g. SL 1234 HR)'),
                        validator: (val) => val?.isEmpty == true ? 'Required' : null,
                      ),
                      TextFormField(
                        controller: priceController,
                        decoration: const InputDecoration(labelText: 'Price Per Day (USD)'),
                        keyboardType: TextInputType.number,
                        validator: (val) => val?.isEmpty == true ? 'Required' : null,
                      ),
                      TextFormField(
                        controller: locationController,
                        decoration: const InputDecoration(labelText: 'Location Name'),
                        validator: (val) => val?.isEmpty == true ? 'Required' : null,
                      ),
                      const SizedBox(height: 20),

                      // Image Upload Section
                      if (isUploadingImage)
                        const SizedBox(
                          height: 120,
                          child: Center(
                            child: CircularProgressIndicator(color: AppColors.primary),
                          ),
                        )
                      else if (currentImageUrl != null && currentImageUrl!.isNotEmpty)
                        Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                currentImageUrl!,
                                height: 150,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => Container(
                                  color: Colors.grey.shade200,
                                  height: 150,
                                  width: double.infinity,
                                  child: const Icon(Icons.broken_image, size: 36, color: Colors.grey),
                                ),
                              ),
                            ),
                            Positioned(
                              top: 8,
                              right: 8,
                              child: InkWell(
                                onTap: () {
                                  setState(() {
                                    currentImageUrl = null;
                                  });
                                },
                                child: CircleAvatar(
                                  backgroundColor: Colors.black.withOpacity(0.6),
                                  radius: 16,
                                  child: const Icon(Icons.close, color: Colors.white, size: 16),
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: 8,
                              left: 8,
                              right: 8,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.6),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: TextButton.icon(
                                  icon: const Icon(Icons.edit_rounded, color: Colors.white, size: 14),
                                  label: const Text(
                                    'Change Image / Beddel Sawirka',
                                    style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                                  ),
                                  onPressed: () async {
                                    final picker = ImagePicker();
                                    final XFile? pickedFile = await picker.pickImage(
                                      source: ImageSource.gallery,
                                      maxWidth: 800,
                                      maxHeight: 800,
                                      imageQuality: 85,
                                    );
                                    if (pickedFile != null) {
                                      setState(() {
                                        isUploadingImage = true;
                                      });
                                      try {
                                        final bytes = await pickedFile.readAsBytes();
                                        final storage = ref.read(storageServiceProvider);
                                        final uploadedUrl = await storage.uploadBytes(
                                          uid: 'admin_vehicle',
                                          fileName: 'car_${DateTime.now().millisecondsSinceEpoch}.jpg',
                                          bytes: bytes,
                                        );
                                        setState(() {
                                          currentImageUrl = uploadedUrl;
                                          isUploadingImage = false;
                                        });
                                      } catch (e) {
                                        setState(() {
                                          isUploadingImage = false;
                                        });
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text('Upload failed: $e'),
                                              backgroundColor: AppColors.cancelled,
                                            ),
                                          );
                                        }
                                      }
                                    }
                                  },
                                ),
                              ),
                            ),
                          ],
                        )
                      else
                        InkWell(
                          onTap: () async {
                            final picker = ImagePicker();
                            final XFile? pickedFile = await picker.pickImage(
                              source: ImageSource.gallery,
                              maxWidth: 800,
                              maxHeight: 800,
                              imageQuality: 85,
                            );
                            if (pickedFile != null) {
                              setState(() {
                                isUploadingImage = true;
                              });
                              try {
                                final bytes = await pickedFile.readAsBytes();
                                final storage = ref.read(storageServiceProvider);
                                final uploadedUrl = await storage.uploadBytes(
                                  uid: 'admin_vehicle',
                                  fileName: 'car_${DateTime.now().millisecondsSinceEpoch}.jpg',
                                  bytes: bytes,
                                );
                                setState(() {
                                  currentImageUrl = uploadedUrl;
                                  isUploadingImage = false;
                                });
                              } catch (e) {
                                setState(() {
                                  isUploadingImage = false;
                                });
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Upload failed: $e'),
                                      backgroundColor: AppColors.cancelled,
                                    ),
                                  );
                                }
                              }
                            }
                          },
                          child: Container(
                            height: 120,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: isDark ? AppColors.surfaceDark : Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_a_photo_outlined, color: AppColors.primary, size: 32),
                                const SizedBox(height: 8),
                                const Text(
                                  'Upload Vehicle Image / Gudbi Sawirka',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Select an image of the car',
                                  style: TextStyle(color: Colors.grey.shade500, fontSize: 10),
                                ),
                              ],
                            ),
                          ),
                        ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogCtx),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () async {
                  if (formKey.currentState?.validate() == true) {
                    final brand = brandController.text.trim();
                    final model = modelController.text.trim();
                    final year = int.tryParse(yearController.text.trim()) ?? 2020;
                    final color = colorController.text.trim();
                    final plate = plateController.text.trim();
                    final price = double.tryParse(priceController.text.trim()) ?? 20.0;
                    final locName = locationController.text.trim();
                    final img = currentImageUrl ?? '';

                    final finalImg = img.isNotEmpty
                        ? img
                        : 'https://images.unsplash.com/photo-1549399542-7e3f8b79c341?auto=format&fit=crop&w=600';

                    final newCar = CarEntity(
                      carId: car?.carId ?? 'car_${DateTime.now().millisecondsSinceEpoch}',
                      brand: brand,
                      model: model,
                      year: year,
                      color: color,
                      plateNumber: plate,
                      category: selectedCategory,
                      pricePerDay: price,
                      currency: 'USD',
                      isAvailable: car?.isAvailable ?? true,
                      features: car?.features ?? ['AC', 'Automatic', 'Bluetooth'],
                      images: [finalImg],
                      location: car?.location ?? const LocationPoint(9.5624, 44.0770),
                      locationName: locName,
                      ownerId: 'admin123',
                      averageRating: car?.averageRating ?? 5.0,
                      totalReviews: car?.totalReviews ?? 1,
                      createdAt: car?.createdAt ?? DateTime.now(),
                    );

                    final repo = ref.read(carRepositoryProvider);
                    if (car == null) {
                      await repo.createCar(newCar);
                    } else {
                      await repo.updateCar(newCar);
                    }

                    // Invalidate cache
                    ref.invalidate(carsListProvider);
                    if (dialogCtx.mounted) {
                      Navigator.pop(dialogCtx);
                    }
                    Helpers.triggerHapticLight();
                  }
                },
                child: const Text('Save'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showDeleteConfirm(BuildContext context, WidgetRef ref, CarEntity car) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Delete Vehicle?'),
        content: Text('Are you sure you want to delete the registered ${car.brand} ${car.model}? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogCtx);
              Helpers.triggerHapticLight();
              await ref.read(carRepositoryProvider).removeCar(car.carId);
              ref.invalidate(carsListProvider);
            },
            child: const Text('Yes, Delete', style: TextStyle(color: AppColors.cancelled)),
          ),
        ],
      ),
    );
  }
}
