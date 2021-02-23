class ItkM1 < Formula
  desc "Insight Toolkit is a toolkit for performing registration and segmentation"
  homepage "https://itk.org"
  license "Apache-2.0"
  head "https://github.com/InsightSoftwareConsortium/ITK.git"

  stable do
    url "https://github.com/InsightSoftwareConsortium/ITK/releases/download/v5.1.2/InsightToolkit-5.1.2.tar.gz"
    sha256 "f1e5a78e11125348f68f655c6b89b617c3a8b2c09f710081f621054811a70c98"
  
    patch do
      url "https://raw.githubusercontent.com/tezheng/homebrew-m1/5bc23fbf9d28a94bc9d3642d20c97ec76eb5b464/Patch/itk/v5.1.2.patch"
      sha256 "75f7fb6c7c53c9f7d5508073df024de966b8a5a03257f993c06b6ac4520d68f8"
    end
  end

  livecheck do
    url :stable
    regex(/^v?(\d+(?:\.\d+)+)$/i)
  end

  bottle do
    sha256 big_sur:  "d471032839867a33b3199917b679a47fe31f32923c8362008df8ab661dffeec2"
    sha256 catalina: "9ef1d85a062b42910f7d8e4cd6f09dad9c8d8eb85fd3ac7f31e253e17ee6d80d"
    sha256 mojave:   "e72bc2bd7cc17c6671aa05bc8c545cc263501c38758fef7521094ed2acb3c57b"
  end

  depends_on "cmake" => :build
  depends_on "zlib"
  depends_on "expat"
  depends_on "fftw"
  depends_on "gdcm"
  depends_on "hdf5"
  depends_on "jpeg"
  depends_on "libpng"
  depends_on "libtiff"
  depends_on "vtk@8.2" # needed for gdcm

  on_linux do
    depends_on "alsa-lib"
    depends_on "unixodbc"
  end

  def install
    args = std_cmake_args + %W[
      -DCMAKE_BUILD_TYPE=Release
      -DCMAKE_INSTALL_RPATH:STRING=#{lib}
      -DCMAKE_INSTALL_NAME_DIR:STRING=#{lib}
      -DBUILD_SHARED_LIBS=ON
      -DBUILD_TESTING=OFF
      -DITK_USE_64BITS_IDS=ON
      -DITK_USE_SYSTEM_ZLIB=ON
      -DITK_USE_SYSTEM_EXPAT=ON
      -DITKV3_COMPATIBILITY:BOOL=OFF
      -DITK_USE_SYSTEM_FFTW=ON
      -DITK_USE_FFTWF=ON
      -DITK_USE_FFTWD=ON
      -DITK_USE_SYSTEM_HDF5=ON
      -DITK_USE_SYSTEM_JPEG=ON
      -DITK_USE_SYSTEM_PNG=ON
      -DITK_USE_SYSTEM_TIFF=ON
      -DITK_USE_SYSTEM_GDCM=ON
      -DITK_LEGACY_REMOVE=ON
      -DITK_USE_GPU=ON
      -DModule_ITKReview=ON
      -DModule_ITKVtkGlue=ON
      -DModule_ITKTestKernel:INTERNAL=OFF
      -DModule_ITKTestKernel-ADVANCED:INTERNAL=OFF
      -DModule_SCIFIO=ON
    ]

    # Avoid references to the Homebrew shims directory
    inreplace "Modules/Core/Common/src/CMakeLists.txt" do |s|
      s.gsub!(/MAKE_MAP_ENTRY\(\s*\\"CMAKE_C_COMPILER\\",
              \s*\\"\${CMAKE_C_COMPILER}\\".*\);/x,
              "MAKE_MAP_ENTRY(\\\"CMAKE_C_COMPILER\\\", " \
              "\\\"#{ENV.cc}\\\", \\\"The C compiler.\\\");")

      s.gsub!(/MAKE_MAP_ENTRY\(\s*\\"CMAKE_CXX_COMPILER\\",
              \s*\\"\${CMAKE_CXX_COMPILER}\\".*\);/x,
              "MAKE_MAP_ENTRY(\\\"CMAKE_CXX_COMPILER\\\", " \
              "\\\"#{ENV.cxx}\\\", \\\"The CXX compiler.\\\");")
    end

    mkdir "build" do
      system "cmake", "..", *args
      system "make"
      system "make", "install"
    end
  end

  test do
    (testpath/"test.cxx").write <<-EOS
      #include "itkImage.h"
      int main(int argc, char* argv[])
      {
        typedef itk::Image<unsigned short, 3> ImageType;
        ImageType::Pointer image = ImageType::New();
        image->Update();
        return EXIT_SUCCESS;
      }
    EOS

    v = version.major_minor
    # Build step
    system ENV.cxx, "-std=c++11", "-isystem", "#{include}/ITK-#{v}", "-o", "test.cxx.o", "-c", "test.cxx"
    # Linking step
    system ENV.cxx, "-std=c++11", "test.cxx.o", "-o", "test",
                    "#{lib}/libITKCommon-#{v}.1.dylib",
                    "#{lib}/libITKVNLInstantiation-#{v}.1.dylib",
                    "#{lib}/libitkvnl_algo-#{v}.1.dylib",
                    "#{lib}/libitkvnl-#{v}.1.dylib"
    system "./test"
  end
end
