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
  var selectedMonsterId = game.selectedMonsterId;
  var selectedSlot = AccessorySlot.hat;
  var stepIndex = 0;
  var showAccessoryPreview = true;
  String? selectedAccessoryId;

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: const Color(0xFF101010),
    builder: (sheetContext) {
      return StatefulBuilder(
        builder: (context, setDialogState) {
          final monsters = game.availableMonsters;
          final selectedMonster = monsters.firstWhere(
            (monster) => monster.id == selectedMonsterId,
            orElse: () => monsters.first,
          );
          final selectedMonsterUnlocked = game.isMonsterUnlocked(
            selectedMonster.id,
          );
          final selectedMonsterEquipped = game.isMonsterSelected(
            selectedMonster.id,
          );
          final monsterPreviewPath =
              'assets/images/characters/${selectedMonster.assetFolder}/$previewState.png';

          final accessoriesForMonster = game.accessoriesFor(
            monsterId: selectedMonster.id,
          );
          final equippedAccessoryId = game.equippedAccessoryIdForTarget(
            monsterId: selectedMonster.id,
            slot: selectedSlot,
          );
          final equippedAccessoryForSlot = equippedAccessoryId == null
              ? null
              : AccessoryCatalog.byId(equippedAccessoryId);

          const availableSlots = AccessorySlot.values;
          if (!availableSlots.contains(selectedSlot)) {
            selectedSlot = AccessorySlot.hat;
          }

          if (selectedAccessoryId == null && equippedAccessoryForSlot != null) {
            selectedSlot = equippedAccessoryForSlot.slot;
          }

          final accessories = accessoriesForMonster
              .where((item) => item.slot == selectedSlot)
              .toList();

          if (selectedAccessoryId == null ||
              !accessories.any((item) => item.id == selectedAccessoryId)) {
            if (equippedAccessoryForSlot != null &&
                equippedAccessoryForSlot.slot == selectedSlot &&
                accessories.any((item) => item.id == equippedAccessoryForSlot.id)) {
              selectedAccessoryId = equippedAccessoryForSlot.id;
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
                  monsterId: selectedMonster.id,
                )
              : false;
          final previewAccessory = selectedAccessory ?? equippedAccessoryForSlot;
          final selectedAccessoryPreviewPath = previewAccessory == null
              ? null
              : 'assets/images/${previewAccessory.assetPath}';

          final media = MediaQuery.of(context);
          final contentHeight = media.size.height * 0.94;

          return SafeArea(
            child: SizedBox(
              height: contentHeight,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Customization',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.of(sheetContext).pop(),
                          icon: const Icon(Icons.close, color: Colors.white70),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Coins: $coins',
                      style: const TextStyle(
                        color: Color(0xFFFFD54F),
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      height: 180,
                      decoration: BoxDecoration(
                        color: const Color(0x22000000),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0x40FFFFFF)),
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Positioned.fill(
                            child: Image.asset(monsterPreviewPath, fit: BoxFit.contain),
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
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ChoiceChip(
                          label: const Text('Idle'),
                          selected: previewState == 'idle',
                          onSelected: (_) =>
                              setDialogState(() => previewState = 'idle'),
                        ),
                        ChoiceChip(
                          label: const Text('Happy'),
                          selected: previewState == 'happy',
                          onSelected: (_) =>
                              setDialogState(() => previewState = 'happy'),
                        ),
                        ChoiceChip(
                          label: const Text('Sad'),
                          selected: previewState == 'sad',
                          onSelected: (_) =>
                              setDialogState(() => previewState = 'sad'),
                        ),
                        FilterChip(
                          label: const Text('Preview'),
                          selected: showAccessoryPreview,
                          onSelected: (value) =>
                              setDialogState(() => showAccessoryPreview = value),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: List.generate(3, (index) {
                        final active = stepIndex == index;
                        final title = index == 0
                            ? '1. Monster'
                            : index == 1
                                ? '2. Group'
                                : '3. Settings';
                        final canTap = index == 0 ||
                            (index == 1 && selectedMonsterUnlocked) ||
                            (index == 2 && selectedMonsterUnlocked);
                        return Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(
                              left: index == 0 ? 0 : 4,
                              right: index == 2 ? 0 : 4,
                            ),
                            child: ChoiceChip(
                              label: Text(
                                title,
                                textAlign: TextAlign.center,
                              ),
                              selected: active,
                              onSelected: canTap
                                  ? (_) => setDialogState(() {
                                      stepIndex = index;
                                    })
                                  : null,
                            ),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (stepIndex == 0) ...[
                              const Text(
                                'Choose Monster',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 8),
                              ...monsters.map((monster) {
                                final unlocked = game.isMonsterUnlocked(monster.id);
                                final equipped = game.isMonsterSelected(monster.id);
                                final selected = selectedMonsterId == monster.id;
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  child: ListTile(
                                    onTap: () {
                                      setDialogState(() {
                                        selectedMonsterId = monster.id;
                                        selectedAccessoryId = null;
                                      });
                                    },
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
                                      monster.label,
                                      style: const TextStyle(color: Colors.white),
                                    ),
                                    subtitle: Text(
                                      unlocked
                                          ? (equipped ? 'Using in game' : 'Owned')
                                          : '${monster.unlockCost} coins',
                                      style: const TextStyle(color: Colors.white70),
                                    ),
                                  ),
                                );
                              }),
                              if (selectedMonsterUnlocked && !selectedMonsterEquipped)
                                OutlinedButton(
                                  onPressed: () async {
                                    await game.selectMonster(selectedMonster.id);
                                    if (!context.mounted) return;
                                    setDialogState(() {
                                      selectedMonsterId = game.selectedMonsterId;
                                    });
                                  },
                                  child: const Text('Use This Monster In Game'),
                                ),
                            ],
                            if (stepIndex == 1) ...[
                              Text(
                                'Choose Group for ${selectedMonster.label}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: availableSlots.map((slot) {
                                  final count = accessoriesForMonster
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
                              const SizedBox(height: 12),
                              Text(
                                accessories.isEmpty
                                    ? 'No ${_shopSlotLabel(selectedSlot).toLowerCase()} available for this monster yet.'
                                    : 'Tap Next to open ${_shopSlotLabel(selectedSlot)} settings.',
                                style: const TextStyle(color: Colors.white70),
                              ),
                            ],
                            if (stepIndex == 2) ...[
                              Text(
                                '${_shopSlotLabel(selectedSlot)} Settings',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 8),
                              if (accessories.isEmpty)
                                Text(
                                  'No ${_shopSlotLabel(selectedSlot).toLowerCase()} for this monster yet.',
                                  style: const TextStyle(color: Colors.white70),
                                ),
                              ...accessories.map((item) {
                                final unlocked = game.isAccessoryUnlocked(item.id);
                                final equipped = game.isAccessoryEquipped(
                                  accessoryId: item.id,
                                  monsterId: selectedMonster.id,
                                );
                                final selected = selectedAccessoryId == item.id;
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  child: ListTile(
                                    onTap: () {
                                      setDialogState(() {
                                        selectedAccessoryId = item.id;
                                      });
                                    },
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
                                  ),
                                );
                              }),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        if (stepIndex > 0)
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => setDialogState(() {
                                stepIndex -= 1;
                              }),
                              child: const Text('Back'),
                            ),
                          ),
                        if (stepIndex > 0) const SizedBox(width: 10),
                        Expanded(
                          child: Builder(
                            builder: (context) {
                              if (stepIndex == 0) {
                                if (!selectedMonsterUnlocked) {
                                  return ElevatedButton(
                                    onPressed: coins >= selectedMonster.unlockCost
                                        ? () async {
                                            final ok = await game.unlockMonster(
                                              selectedMonster.id,
                                            );
                                            if (!ok || !context.mounted) return;
                                            await game.selectMonster(
                                              selectedMonster.id,
                                            );
                                            if (!context.mounted) return;
                                            setDialogState(() {
                                              coins = game.totalCoins;
                                              selectedMonsterId =
                                                  game.selectedMonsterId;
                                              stepIndex = 1;
                                            });
                                          }
                                        : null,
                                    child: Text(
                                      'Unlock & Select (${selectedMonster.unlockCost})',
                                    ),
                                  );
                                }
                                return ElevatedButton(
                                  onPressed: () => setDialogState(() {
                                    final firstSlotWithItems =
                                        AccessorySlot.values.where((slot) {
                                      return accessoriesForMonster.any(
                                        (item) => item.slot == slot,
                                      );
                                    });
                                    selectedSlot = firstSlotWithItems.isEmpty
                                        ? AccessorySlot.hat
                                        : firstSlotWithItems.first;
                                    selectedAccessoryId = null;
                                    stepIndex = 1;
                                  }),
                                  child: const Text('Next: Group'),
                                );
                              }

                              if (stepIndex == 1) {
                                return ElevatedButton(
                                  onPressed: selectedMonsterUnlocked
                                      ? () => setDialogState(() {
                                          stepIndex = 2;
                                        })
                                      : null,
                                  child: const Text('Next: Settings'),
                                );
                              }

                              if (selectedAccessory == null) {
                                return const ElevatedButton(
                                  onPressed: null,
                                  child: Text('Select Item'),
                                );
                              }
                              if (!selectedAccessoryUnlocked) {
                                return ElevatedButton(
                                  onPressed: coins >= selectedAccessory.cost
                                      ? () async {
                                          final ok = await game.unlockAccessory(
                                            selectedAccessory.id,
                                          );
                                          if (!ok || !context.mounted) return;
                                          await game.setAccessoryEquipped(
                                            selectedAccessory.id,
                                            monsterId: selectedMonster.id,
                                          );
                                          if (!context.mounted) return;
                                          setDialogState(() {
                                            coins = game.totalCoins;
                                          });
                                        }
                                      : null,
                                  child: Text(
                                    'Buy & Equip (${selectedAccessory.cost})',
                                  ),
                                );
                              }
                              if (!selectedAccessoryEquipped) {
                                return ElevatedButton(
                                  onPressed: () async {
                                    await game.setAccessoryEquipped(
                                      selectedAccessory.id,
                                      monsterId: selectedMonster.id,
                                    );
                                    if (!context.mounted) return;
                                    setDialogState(() {
                                      coins = game.totalCoins;
                                    });
                                  },
                                  child: const Text('Equip'),
                                );
                              }
                              return ElevatedButton(
                                onPressed: () async {
                                  await game.clearEquippedAccessory(
                                    monsterId: selectedMonster.id,
                                    slot: selectedSlot,
                                  );
                                  if (!context.mounted) return;
                                  setDialogState(() {
                                    selectedAccessoryId = null;
                                  });
                                },
                                child: const Text('Unequip'),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    },
  );
}
