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

enum _ShopPrimaryAction {
  unlockMonster,
  nextGroup,
  nextSettings,
  selectItem,
  buyEquip,
  equip,
  unequip,
}

String _primaryActionLabel(_ShopPrimaryAction action, MonsterCharacter monster, AccessoryItem? item) {
  switch (action) {
    case _ShopPrimaryAction.unlockMonster:
      return 'Unlock & Select (${monster.unlockCost})';
    case _ShopPrimaryAction.nextGroup:
      return 'Next: Group';
    case _ShopPrimaryAction.nextSettings:
      return 'Next: Settings';
    case _ShopPrimaryAction.selectItem:
      return 'Select Item';
    case _ShopPrimaryAction.buyEquip:
      return 'Buy & Equip (${item?.cost ?? 0})';
    case _ShopPrimaryAction.equip:
      return 'Equip';
    case _ShopPrimaryAction.unequip:
      return 'Unequip';
  }
}

AccessoryItem? _accessoryById(List<AccessoryItem> items, String? id) {
  if (id == null) return null;
  for (final item in items) {
    if (item.id == id) return item;
  }
  return null;
}

AccessorySlot _firstSlotWithItems(List<AccessoryItem> items) {
  for (final slot in AccessorySlot.values) {
    if (items.any((item) => item.slot == slot)) {
      return slot;
    }
  }
  return AccessorySlot.hat;
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
          final selectedMonsterUnlocked = game.isMonsterUnlocked(selectedMonster.id);
          final selectedMonsterEquipped = game.isMonsterSelected(selectedMonster.id);

          final allAccessories = game.accessoriesFor(monsterId: selectedMonster.id);
          final slotAccessories = allAccessories
              .where((item) => item.slot == selectedSlot)
              .toList();

          final selectedAccessory = _accessoryById(slotAccessories, selectedAccessoryId);
          final equippedAccessoryId = game.equippedAccessoryIdForTarget(
            monsterId: selectedMonster.id,
            slot: selectedSlot,
          );
          final equippedAccessory = AccessoryCatalog.byId(equippedAccessoryId ?? '');
          final previewAccessory = selectedAccessory ?? equippedAccessory;

          final selectedAccessoryUnlocked =
              selectedAccessory != null && game.isAccessoryUnlocked(selectedAccessory.id);
          final selectedAccessoryEquipped =
              selectedAccessory != null && game.isAccessoryEquipped(
                accessoryId: selectedAccessory.id,
                monsterId: selectedMonster.id,
              );

          final primaryAction = stepIndex == 0
              ? (!selectedMonsterUnlocked
                    ? _ShopPrimaryAction.unlockMonster
                    : _ShopPrimaryAction.nextGroup)
              : stepIndex == 1
                  ? _ShopPrimaryAction.nextSettings
                  : selectedAccessory == null
                      ? _ShopPrimaryAction.selectItem
                      : !selectedAccessoryUnlocked
                          ? _ShopPrimaryAction.buyEquip
                          : selectedAccessoryEquipped
                              ? _ShopPrimaryAction.unequip
                              : _ShopPrimaryAction.equip;

          final primaryEnabled = switch (primaryAction) {
            _ShopPrimaryAction.unlockMonster => coins >= selectedMonster.unlockCost,
            _ShopPrimaryAction.nextGroup => true,
            _ShopPrimaryAction.nextSettings => selectedMonsterUnlocked,
            _ShopPrimaryAction.selectItem => false,
            _ShopPrimaryAction.buyEquip => coins >= (selectedAccessory?.cost ?? 0),
            _ShopPrimaryAction.equip => true,
            _ShopPrimaryAction.unequip => true,
          };

          Future<void> runPrimaryAction() async {
            switch (primaryAction) {
              case _ShopPrimaryAction.unlockMonster:
                final ok = await game.unlockMonster(selectedMonster.id);
                if (!ok || !context.mounted) return;
                await game.selectMonster(selectedMonster.id);
                if (!context.mounted) return;
                setDialogState(() {
                  coins = game.totalCoins;
                  selectedMonsterId = game.selectedMonsterId;
                  selectedSlot = _firstSlotWithItems(allAccessories);
                  selectedAccessoryId = null;
                  stepIndex = 1;
                });
                break;
              case _ShopPrimaryAction.nextGroup:
                setDialogState(() {
                  selectedSlot = _firstSlotWithItems(allAccessories);
                  selectedAccessoryId = null;
                  stepIndex = 1;
                });
                break;
              case _ShopPrimaryAction.nextSettings:
                setDialogState(() {
                  stepIndex = 2;
                });
                break;
              case _ShopPrimaryAction.selectItem:
                break;
              case _ShopPrimaryAction.buyEquip:
                final item = selectedAccessory;
                if (item == null) return;
                final ok = await game.unlockAccessory(item.id);
                if (!ok || !context.mounted) return;
                await game.setAccessoryEquipped(item.id, monsterId: selectedMonster.id);
                if (!context.mounted) return;
                setDialogState(() {
                  coins = game.totalCoins;
                });
                break;
              case _ShopPrimaryAction.equip:
                final item = selectedAccessory;
                if (item == null) return;
                await game.setAccessoryEquipped(item.id, monsterId: selectedMonster.id);
                if (!context.mounted) return;
                setDialogState(() {
                  coins = game.totalCoins;
                });
                break;
              case _ShopPrimaryAction.unequip:
                await game.clearEquippedAccessory(
                  monsterId: selectedMonster.id,
                  slot: selectedSlot,
                );
                if (!context.mounted) return;
                setDialogState(() {
                  selectedAccessoryId = null;
                });
                break;
            }
          }

          final media = MediaQuery.of(context);

          return SafeArea(
            child: SizedBox(
              height: media.size.height * 0.94,
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
                            child: Image.asset(
                              'assets/images/characters/${selectedMonster.assetFolder}/$previewState.png',
                              fit: BoxFit.contain,
                            ),
                          ),
                          if (showAccessoryPreview && previewAccessory != null)
                            Positioned.fill(
                              child: Opacity(
                                opacity: 0.95,
                                child: Image.asset(
                                  'assets/images/${previewAccessory.assetPath}',
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
                        for (final state in const ['idle', 'happy', 'sad'])
                          ChoiceChip(
                            label: Text(state[0].toUpperCase() + state.substring(1)),
                            selected: previewState == state,
                            onSelected: (_) => setDialogState(() {
                              previewState = state;
                            }),
                          ),
                        FilterChip(
                          label: const Text('Preview'),
                          selected: showAccessoryPreview,
                          onSelected: (value) => setDialogState(() {
                            showAccessoryPreview = value;
                          }),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: List.generate(3, (index) {
                        final labels = ['1. Monster', '2. Group', '3. Settings'];
                        final canTap = index == 0 || selectedMonsterUnlocked;
                        return Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(left: index == 0 ? 0 : 4),
                            child: ChoiceChip(
                              label: Text(labels[index], textAlign: TextAlign.center),
                              selected: stepIndex == index,
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
                                final selected = selectedMonsterId == monster.id;
                                final unlocked = game.isMonsterUnlocked(monster.id);
                                final equipped = game.isMonsterSelected(monster.id);
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  child: ListTile(
                                    onTap: () {
                                      setDialogState(() {
                                        selectedMonsterId = monster.id;
                                        selectedSlot = _firstSlotWithItems(
                                          game.accessoriesFor(monsterId: monster.id),
                                        );
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
                                children: AccessorySlot.values.map((slot) {
                                  final count = allAccessories
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
                              if (slotAccessories.isEmpty)
                                Text(
                                  'No ${_shopSlotLabel(selectedSlot).toLowerCase()} for this monster yet.',
                                  style: const TextStyle(color: Colors.white70),
                                ),
                              ...slotAccessories.map((item) {
                                final selected = selectedAccessoryId == item.id;
                                final unlocked = game.isAccessoryUnlocked(item.id);
                                final equipped = game.isAccessoryEquipped(
                                  accessoryId: item.id,
                                  monsterId: selectedMonster.id,
                                );
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
                          child: ElevatedButton(
                            onPressed: primaryEnabled ? runPrimaryAction : null,
                            child: Text(
                              _primaryActionLabel(
                                primaryAction,
                                selectedMonster,
                                selectedAccessory,
                              ),
                            ),
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
