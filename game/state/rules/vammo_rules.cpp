#include "game/state/gamestate.h"
#include "game/state/rules/vammo_type.h"

namespace OpenApoc
{

template <> const UString &StateObject<VAmmoType>::getPrefix()
{
	static UString prefix = "VAMMOTYPE_";
	return prefix;
}

template <> const UString &StateObject<VAmmoType>::getTypeName()
{
	static UString name = "VAmmoType";
	return name;
}

template <> sp<VAmmoType> StateObject<VAmmoType>::get(const GameState &state, const UString &id)
{
	auto it = state.vehicle_ammo.find(id);
	if (it == state.vehicle_ammo.end())
	{
		LogError("No vammo type matching ID \"%s\"", id);
		return nullptr;
	}
	return it->second;
}
}
