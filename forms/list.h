
#pragma once

#include "forms/control.h"
#include "forms/forms_enums.h"
#include "library/colour.h"
#include "library/sp.h"

namespace OpenApoc
{

class ScrollBar;

class ListBox : public Control
{
  private:
	bool scroller_is_internal;
	sp<Control> hovered, selected;
	Vec2<int> scrollOffset = {0, 0};

	void configureInternalScrollBar();

  protected:
	void onRender() override;
	void postRender() override;

  public:
	sp<ScrollBar> scroller;
	int ItemSize, ItemSpacing;
	Orientation ListOrientation, ScrollOrientation;
	Colour HoverColour, SelectedColour;
	bool AlwaysEmitSelectionEvents;

	ListBox();
	ListBox(sp<ScrollBar> ExternalScrollBar);
	~ListBox() override;

	void eventOccured(Event *e) override;
	void update() override;
	void unloadResources() override;

	void setSelected(sp<Control> c);

	void clear();
	void addItem(sp<Control> Item);
	sp<Control> removeItem(sp<Control> Item);
	sp<Control> removeItem(int Index);
	sp<Control> operator[](int Index);

	sp<Control> copyTo(sp<Control> CopyParent) override;
	void configureSelfFromXml(pugi::xml_node *node) override;

	template <typename T> sp<T> getHoveredData() const
	{
		if (hovered != nullptr)
		{
			return hovered->getData<T>();
		}
		return nullptr;
	}

	template <typename T> sp<T> getSelectedData() const
	{
		if (selected != nullptr)
		{
			return selected->getData<T>();
		}
		return nullptr;
	}
};

}; // namespace OpenApoc
