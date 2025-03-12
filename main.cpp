#include <vector>
#include <string>
#include <map>

#include "lib/thread_pool.hpp"
#include "Image.h"

#define NUM_GIF_FRAMES 6

void workBW(int i, int index, std::vector<std::map<std::pair<int, int>, Image>>& preloadedResized);
void workCol(int i, int index, std::vector<std::map<std::pair<int, int>, Image>>& preloadedResized);

void createVideoFramesBW(int start, int end, int repeatFrames, int gif_start, int num_gif_frames);
void createVideoFramesCol(int start, int end, int repeatFrames, int gif_start, int num_gif_frames);

void showUsage() {
    std::cout<<"Usage: [?.exe] type start end [SFRC] [gif_start] [gif_frames]\n"
             <<"type:       Black and White or Colored Image Sequence ('BW' or 'Col')\n"
             <<"start:      Frame to start on (int)\n"
             <<"end:        Frame to end on (int)\n"
             <<"SFRC:       How often to repeat Sprite frames (default 2)\n"
	     <<"gif_start:  Starting frame to use for GIF from the `res` dir (default 0)\n"
	     <<"gif_frames: How much frames to assume for the GIF file in the `res` dir (default "<<NUM_GIF_FRAMES<<")"<<std::endl;
}

int main(int argc, char *argv[0]) {
    std::string type;
    int start, end, repeatFrames;
    int num_gif_frames = NUM_GIF_FRAMES;
    int gif_start = 0;
    if (argc < 4) {
        showUsage();
        return 0;
    } else {
        type = argv[1];
        start = std::stoi(argv[2]);
        end = std::stoi(argv[3]);
        repeatFrames = 2;
    }
    if (argc > 4) {
        repeatFrames = std::stoi(argv[4]);
    }
    if (argc > 5) {
	gif_start = std::stoi(argv[5]);
    }
    if (argc > 6) {
	num_gif_frames = std::stoi(argv[6]);
    }

    if (type == "BW") {
        createVideoFramesBW(start, end, repeatFrames, gif_start, num_gif_frames);
    } else if (type == "Col") {
        createVideoFramesCol(start, end, repeatFrames, gif_start, num_gif_frames);
    } else {
        showUsage();
        return 0;
    }

    std::cout<<"\n\nDone"<<std::endl;
    return 0;
}


void createVideoFramesBW(int start, int end, int repeatFrames, int gif_start, int num_gif_frames) {

    std::vector<std::map<std::pair<int, int>, Image>> preloadedResized;
    int width;
    int height;
    std::string first_name("in/img_" + std::to_string(start) + ".png");
    Image first_frame(first_name.c_str());
    width = first_frame.w;
    height = first_frame.h;

    for (int i = gif_start; i < num_gif_frames; i++) {
        std::string amogus_name("res/" + std::to_string(i) + ".png");
        Image amogus(amogus_name.c_str());

        preloadedResized.push_back(amogus.preloadResized(width, height));
    }

    thread_pool pool;
    int frame_count = num_gif_frames-gif_start;

    for (int i = start; i <= end; i++) {
        int index = floor((i % (frame_count*repeatFrames))/repeatFrames);
        pool.submit(workBW, i, index, std::ref(preloadedResized));
    }

    pool.wait_for_tasks();
}

void workBW(int i, int index, std::vector<std::map<std::pair<int, int>, Image>>& preloadedResized) {
    std::string frame_name("in/img_" + std::to_string(i) + ".png");
    Image frame(frame_name.c_str());
    Image frame_done = frame.quadifyFrameBW(preloadedResized.at(index));
    std::string save_loc("out/img_" + std::to_string(i) + ".png");
    frame_done.write(save_loc.c_str());
    std::cout<<i<<"\n";
}

void createVideoFramesCol(int start, int end, int repeatFrames, int gif_start, int num_gif_frames) {

    std::vector<std::map<std::pair<int, int>, Image>> preloadedResized;
    int width;
    int height;
    std::string first_name("in/img_" + std::to_string(start) + ".png");
    Image first_frame(first_name.c_str());
    width = first_frame.w;
    height = first_frame.h;

    for (int i = gif_start; i < num_gif_frames; i++) {
        std::string amogus_name("res/" + std::to_string(i) + ".png");
        Image amogus(amogus_name.c_str());

        preloadedResized.push_back(amogus.preloadResized(width, height));
    }

    thread_pool pool;
    int frame_count = num_gif_frames-gif_start;

    for (int i = start; i <= end; i++) {
        int index = floor((i % (frame_count*repeatFrames))/repeatFrames);
        pool.submit(workCol, i, index, std::ref(preloadedResized));
    }

    pool.wait_for_tasks();
}

void workCol(int i, int index, std::vector<std::map<std::pair<int, int>, Image>>& preloadedResized) {
    std::string frame_name("in/img_" + std::to_string(i) + ".png");
    Image frame(frame_name.c_str());
    Image frame_done = frame.quadifyFrameRGB(preloadedResized.at(index));
    std::string save_loc("out/img_" + std::to_string(i) + ".png");
    frame_done.write(save_loc.c_str());
    std::cout<<i<<"\n";
}
