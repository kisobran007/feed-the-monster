part of '../../main.dart';

String _shopSlotLabel(AccessorySlot slot) {
  switch (slot) {
    case AccessorySlot.hat:
      return 'Hats';
    case AccessorySlot.shoes:
      return 'Footwear';
    case AccessorySlot.outfit:
      return 'Outfits';
  }
}

Future<void> showShopDialog(
  BuildContext context,
  MonsterTapGame game,
) async {
  await game.loadCustomizationProgress();
  if (!context.mounted) return;

  var previewState = 'idle';
  var coins = game.totalCoins;
  var selectedSkinId = game.selectedMonsterId;
  var selectedSlot = AccessorySlot.hat;
  var isAccessoryStep = false;
  var showAccessoryPreview = true;
  String? selectedAccessoryId;

  await showDialog<void>(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setDialogState) {
          final skins = game.availableMonsters;
          final selectedSkin = skins.firstWhere(
            (skin) => skin.id == selectedSkinId,
            orElse: () => skins.first,
          );
          final selectedSkinUnlocked = game.isMonsterUnlocked(selectedSkin.id);
          final selectedSkinEquipped = game.isMonsterSelected(selectedSkin.id);
          final skinAssetFolder = selectedSkin.assetFolder;
          final skinPreviewPath =
              'assets/images/characters/$skinAssetFolder/$previewState.png';

          final accessoriesForSkin = game.accessoriesFor(
            level: GameLevel.level1,
            monsterId: selectedSkin.id,
          );
          final equippedAccessoryId = game.equippedAccessoryIdForTarget(
            level: GameLevel.level1,
            monsterId: selectedSkin.id,
          );
          final equippedAccessory = equippedAccessoryId == null
              ? null
              : AccessoryCatalog.byId(equippedAccessoryId);

          // Initialize preview from the actually equipped item instead of
          // defaulting to the first accessory in the list.
          if (selectedAccessoryId == null && equippedAccessory != null) {
            selectedSlot = equippedAccessory.slot;
          }

          const availableSlots = AccessorySlot.values;
          final accessories = accessoriesForSkin
              .where((item) => item.slot == selectedSlot)
              .toList();
          if (!availableSlots.any((slot) => slot == selectedSlot)) {
            selectedSlot = AccessorySlot.hat;
          }
          if (selectedAccessoryId == null ||
              !accessories.any((item) => item.id == selectedAccessoryId)) {
            if (equippedAccessory != null &&
                equippedAccessory.slot == selectedSlot &&
                accessories.any((item) => item.id == equippedAccessory.id)) {
              selectedAccessoryId = equippedAccessory.id;
            } else {
              selectedAccessoryId = null;
            }
          }
          final selectedAccessory = selectedAccessoryId == null
              ? null
              : accessories.firstWhere((item) => item.id == selectedAccessoryId);
          final selectedAccessoryUnlocked = selectedAccessory != null
              ? game.isAccessoryUnlocked(selectedAccessory.id)
              : false;
          final selectedAccessoryEquipped = selectedAccessory != null
              ? game.isAccessoryEquipped(
                  accessoryId: selectedAccessory.id,
                  level: GameLevel.level1,
                  monsterId: selectedSkin.id,
                )
              : false;
          final selectedAccessoryPreviewPath = selectedAccessory == null
              ? null
              : 'assets/images/${selectedAccessory.assetPath}';

          return AlertDialog(
            backgroundColor: const Color(0xFF1F1F1F),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            title: const Text(
              'Shop',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: SizedBox(
              width: 420,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 520),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Coins: $coins',
                        style: const TextStyle(
                          color: Color(0xFFFFD54F),
                          fontWeight: FontWeight.w700,
                          fontSize: 20,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        height: 200,
                        decoration: BoxDecoration(
                          color: const Color(0x33000000),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0x55FFFFFF)),
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Positioned.fill(
                              child: Image.asset(
                                skinPreviewPath,
                                fit: BoxFit.contain,
                              ),
                            ),
                            if (showAccessoryPreview &&
                                selectedAccessoryPreviewPath != null)
                              Positioned.fill(
                                child: Opacity(
                                  opacity: 0.95,
                                  child: Image.asset(
                                    selectedAccessoryPreviewPath,
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ChoiceChip(
                            label: const Text('Idle'),
                            selected: previewState == 'idle',
                            onSelected: (_) =>
                                setDialogState(() => previewState = 'idle'),
                          ),
                          const SizedBox(width: 8),
                          ChoiceChip(
                            label: const Text('Happy'),
                            selected: previewState == 'happy',
                            onSelected: (_) =>
                                setDialogState(() => previewState = 'happy'),
                          ),
                          const SizedBox(width: 8),
                          ChoiceChip(
                            label: const Text('Sad'),
                            selected: previewState == 'sad',
                            onSelected: (_) =>
                                setDialogState(() => previewState = 'sad'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ChoiceChip(
                            label: const Text('1. Monster'),
                            selected: !isAccessoryStep,
                            onSelected: (_) {
                              setDialogState(() {
                                isAccessoryStep = false;
                              });
                            },
                          ),
                          const SizedBox(width: 8),
                          ChoiceChip(
                            label: const Text('2. Accessories'),
                            selected: isAccessoryStep,
                            onSelected: selectedSkinUnlocked
                                ? (_) {
                                    setDialogState(() {
                                      isAccessoryStep = true;
                                    });
                                  }
                                : null,
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      if (!isAccessoryStep) ...[
                        const Text(
                          'Choose Monster',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...skins.map(
                          (skin) {
                            final unlocked = game.isMonsterUnlocked(skin.id);
                            final equipped = game.isMonsterSelected(skin.id);
                            final selected = selectedSkinId == skin.id;
                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                tileColor: selected
                                    ? const Color(0x2242A5F5)
                                    : const Color(0x22000000),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  side: BorderSide(
                                    color: selected
                                        ? const Color(0xFF42A5F5)
                                        : const Color(0x33FFFFFF),
                                  ),
                                ),
                                title: Text(
                                  skin.label,
                                  style: const TextStyle(color: Colors.white),
                                ),
                                subtitle: Text(
                                  unlocked
                                      ? (equipped ? 'Equipped' : 'Owned')
                                      : '${skin.unlockCost} coins',
                                  style: const TextStyle(color: Colors.white70),
                                ),
                                onTap: () {
                                  setDialogState(() {
                                    selectedSkinId = skin.id;
                                    selectedAccessoryId = null;
                                  });
                                },
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            if (!selectedSkinUnlocked)
                              ElevatedButton(
                                onPressed: coins >= selectedSkin.unlockCost
                                    ? () async {
                                        final ok =
                                            await game.unlockMonster(selectedSkin.id);
                                        if (!ok) return;
                                        await game.selectMonster(selectedSkin.id);
                                        await game.loadCustomizationProgress();
                                        setDialogState(() {
                                          coins = game.totalCoins;
                                          selectedSkinId = game.selectedMonsterId;
                                        });
                                      }
                                    : null,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF43A047),
                                  foregroundColor: Colors.white,
                                ),
                                child: const Text('Buy & Equip'),
                              ),
                            if (selectedSkinUnlocked)
                              ElevatedButton(
                                onPressed: selectedSkinEquipped
                                    ? null
                                    : () async {
                                        await game.selectMonster(selectedSkin.id);
                                        await game.loadCustomizationProgress();
                                        setDialogState(() {
                                          coins = game.totalCoins;
                                          selectedSkinId = game.selectedMonsterId;
                                        });
                                      },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF42A5F5),
                                  foregroundColor: Colors.white,
                                ),
                                child: Text(
                                  selectedSkinEquipped ? 'Equipped' : 'Equip',
                                ),
                              ),
                            ElevatedButton(
                              onPressed: selectedSkinUnlocked
                                  ? () {
                                      setDialogState(() {
                                        final firstSlotWithItems =
                                            AccessorySlot.values.where(
                                          (slot) {
                                            return accessoriesForSkin.any(
                                              (item) => item.slot == slot,
                                            );
                                          },
                                        );
                                        selectedSlot = firstSlotWithItems.isEmpty
                                            ? AccessorySlot.hat
                                            : firstSlotWithItems.first;
                                        selectedAccessoryId = null;
                                        isAccessoryStep = true;
                                      });
                                    }
                                  : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFFFA726),
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('Customize Accessories'),
                            ),
                          ],
                        ),
                      ] else ...[
                        Row(
                          children: [
                            const Expanded(
                              child: Text(
                                'Accessory Categories',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            FilterChip(
                              label: const Text('Preview'),
                              selected: showAccessoryPreview,
                              onSelected: (v) {
                                setDialogState(() {
                                  showAccessoryPreview = v;
                                });
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: availableSlots.map((slot) {
                            final count = accessoriesForSkin
                                .where((item) => item.slot == slot)
                                .length;
                            return ChoiceChip(
                              label: Text('${_shopSlotLabel(slot)} ($count)'),
                              selected: selectedSlot == slot,
                              onSelected: (_) {
                                setDialogState(() {
                                  selectedSlot = slot;
                                  selectedAccessoryId = null;
                                });
                              },
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 10),
                        if (accessories.isEmpty)
                          Text(
                            'No ${_shopSlotLabel(selectedSlot).toLowerCase()} for this monster yet.',
                            style: const TextStyle(color: Colors.white70),
                          ),
                        ...accessories.map(
                          (item) {
                            final unlocked = game.isAccessoryUnlocked(item.id);
                            final equipped = game.isAccessoryEquipped(
                              accessoryId: item.id,
                              level: GameLevel.level1,
                              monsterId: selectedSkin.id,
                            );
                            final selected = selectedAccessoryId == item.id;
                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                tileColor: selected
                                    ? const Color(0x2242A5F5)
                                    : const Color(0x22000000),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  side: BorderSide(
                                    color: selected
                                        ? const Color(0xFF42A5F5)
                                        : const Color(0x33FFFFFF),
                                  ),
                                ),
                                leading: SizedBox(
                                  width: 42,
                                  height: 42,
                                  child: Image.asset(
                                    'assets/images/${item.assetPath}',
                                    fit: BoxFit.contain,
                                  ),
                                ),
                                title: Text(
                                  item.label,
                                  style: const TextStyle(color: Colors.white),
                                ),
                                subtitle: Text(
                                  unlocked
                                      ? (equipped ? 'Equipped' : 'Owned')
                                      : '${item.cost} coins',
                                  style: const TextStyle(color: Colors.white70),
                                ),
                                onTap: () {
                                  setDialogState(() {
                                    selectedAccessoryId = item.id;
                                  });
                                },
                                trailing: unlocked
                                    ? ElevatedButton(
                                        onPressed: equipped
                                            ? null
                                            : () async {
                                                await game.setAccessoryEquipped(
                                                  item.id,
                                                  level: GameLevel.level1,
                                                  monsterId: selectedSkin.id,
                                                );
                                                await game.loadCustomizationProgress();
                                                setDialogState(() {
                                                  coins = game.totalCoins;
                                                  selectedAccessoryId = item.id;
                                                });
                                              },
                                        child: Text(
                                          equipped ? 'Equipped' : 'Equip',
                                        ),
                                      )
                                    : ElevatedButton(
                                        onPressed: coins >= item.cost
                                            ? () async {
                                                final ok = await game
                                                    .unlockAccessory(item.id);
                                                if (!ok) return;
                                                await game.setAccessoryEquipped(
                                                  item.id,
                                                  level: GameLevel.level1,
                                                  monsterId: selectedSkin.id,
                                                );
                                                await game.loadCustomizationProgress();
                                                setDialogState(() {
                                                  coins = game.totalCoins;
                                                  selectedAccessoryId = item.id;
                                                });
                                              }
                                            : null,
                                        child: const Text('Buy'),
                                      ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            OutlinedButton(
                              onPressed: () {
                                setDialogState(() {
                                  isAccessoryStep = false;
                                });
                              },
                              child: const Text('Back to Monsters'),
                            ),
                            if (selectedAccessory != null &&
                                selectedAccessoryUnlocked &&
                                selectedAccessoryEquipped)
                              OutlinedButton(
                                onPressed: () async {
                                  await game.clearEquippedAccessory(
                                    level: GameLevel.level1,
                                    monsterId: selectedSkin.id,
                                  );
                                  await game.loadCustomizationProgress();
                                  setDialogState(() {
                                    coins = game.totalCoins;
                                    selectedAccessoryId = null;
                                  });
                                },
                                child: const Text('Remove Equipped'),
                              ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text(
                  'Close',
                  style: TextStyle(color: Color(0xFF81C784)),
                ),
              ),
            ],
          );
        },
      );
    },
  );
}
