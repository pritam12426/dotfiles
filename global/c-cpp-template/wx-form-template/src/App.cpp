#include "App.h"

#include <wx/wx.h>

#include "FormBuilder.h"

wxIMPLEMENT_APP(App);

bool App::OnInit() {
	MyFrame2* mainFrame = new MyFrame2(NULL);
	mainFrame->Show();
	return true;
};
