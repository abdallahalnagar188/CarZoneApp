import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../commons/models/car_catalog.dart';
import '../../../../commons/models/vehicle_model.dart';
import '../../../../commons/widgets/common_widgets.dart';
import '../../../../core/extensions/sized_box_extension.dart';
import '../../../../core/helpers/plate_helper.dart';
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
          padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 24.h),
          children: [
            Center(child: CarAvatar(color: VehicleModel.colors[controller.color.value]!, size: 96.r)),
            24.height,
            PickerField(
              label: 'cars.make'.tr,
              value: controller.make.value,
              error: controller.errors['make'],
              options: [for (final m in CarCatalog.makes) m.name],
              subtitles: {for (final m in CarCatalog.makes) m.name: m.ar},
              allowCustom: true,
              onSelected: controller.setMake,
            ),
            16.height,
            PickerField(
              label: 'cars.model'.tr,
              value: controller.model.value,
              error: controller.errors['model'],
              options: controller.models,
              // A make we do not list has no models to pick: the model is typed.
              allowCustom: controller.make.value != null,
              onSelected: controller.setModel,
            ),
            16.height,
            AppTextField(
              controller: controller.yearController,
              label: 'cars.year'.tr,
              hint: '${DateTime.now().year}',
              error: controller.errors['year'],
              keyboardType: TextInputType.number,
              maxLength: 4,
              inputFormatters: [const LatinDigitsFormatter(), FilteringTextInputFormatter.digitsOnly],
              onChanged: (_) => controller.errors.remove('year'),
            ),
            16.height,
            Text('cars.color'.tr, style: Theme.of(context).textTheme.titleSmall),
            10.height,
            ColorSwatches(value: controller.color.value, onChanged: controller.setColor),
            20.height,
            PlateInput(
              country: controller.plateCountry.value,
              onCountryChanged: controller.setPlateCountry,
              code: controller.plateCode,
              digits: controller.plateDigits,
              error: controller.errors['plate'],
              onChanged: () => controller.errors.remove('plate'),
            ),
          ],
        ),
      ),
      // Pinned above the home indicator, so saving never needs a scroll.
      bottomNavigationBar: SafeArea(
        minimum: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 12.h),
        child: Obx(
          () => AppButton(
            title: 'profile.save'.tr,
            loading: controller.saving.value,
            onTap: controller.save,
          ),
        ),
      ),
    );
  }
}
