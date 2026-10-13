import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../commons/models/vehicle_model.dart';
import '../../../../commons/widgets/common_widgets.dart';
import '../../../../core/extensions/sized_box_extension.dart';
import '../controllers/cars_controller.dart';
import '../widgets/car_form_fields.dart';

class CarFormPage extends StatefulWidget {
  const CarFormPage({super.key});

  @override
  State<CarFormPage> createState() => _CarFormPageState();
}

class _CarFormPageState extends State<CarFormPage> {
  final controller = Get.find<CarsController>();

  @override
  void initState() {
    super.initState();
    controller.prepareForm();
  }

  @override
  Widget build(BuildContext context) {
    final editing = controller.editingId.value != null;
    return Scaffold(
      appBar: AppTopBar(
        title: (editing ? 'cars.edit' : 'cars.add').tr,
        actions: [
          if (editing)
            AppIconButton(
              glass: true,
              icon: const Icon(Iconsax.trash),
              onTap: () {
                final v = controller.vehicles.firstWhereOrNull((x) => x.id == controller.editingId.value);
                if (v != null) controller.delete(v);
              },
            ),
        ],
      ),
      body: Obx(
        () => ListView(
          padding: EdgeInsets.all(20.r),
          children: [
            Center(child: CarAvatar(color: VehicleModel.colors[controller.color.value]!, size: 96.r)),
            24.height,
            PickerField(
              label: 'cars.make'.tr,
              value: controller.make.value,
              error: controller.errors['make'],
              options: VehicleModel.makes.keys.toList(),
              onSelected: controller.setMake,
            ),
            16.height,
            PickerField(
              label: 'cars.model'.tr,
              value: controller.model.value,
              error: controller.errors['model'],
              options: controller.models,
              onSelected: controller.setModel,
            ),
            16.height,
            AppTextField(
              controller: controller.yearController,
              label: 'cars.year'.tr,
              keyboardType: TextInputType.number,
              maxLength: 4,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
            16.height,
            Text('cars.color'.tr, style: Theme.of(context).textTheme.titleSmall),
            10.height,
            ColorSwatches(value: controller.color.value, onChanged: controller.setColor),
            16.height,
            AppTextField(
              controller: controller.plateController,
              label: 'cars.plate'.tr,
              error: controller.errors['plate'],
              maxLength: 10,
              textDirection: TextDirection.ltr,
              onChanged: (_) => controller.errors.remove('plate'),
            ),
            28.height,
            AppButton(
              title: 'profile.save'.tr,
              loading: controller.saving.value,
              onTap: controller.save,
            ),
          ],
        ),
      ),
    );
  }
}
