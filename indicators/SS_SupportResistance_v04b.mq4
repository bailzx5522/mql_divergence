//+------------------------------------------------------------------+
//|                                         SS_SupportResistance.mq4 |
//|                                  Copyright © 2012, Andrew Sumner |
//|                                                                  |
//| You are allowed to copy and distribute this file as you see fit, |
//| and modify it to suit your purposes on the following condition:- |
//|                                                                  |
//| 1. You must charge no money for this indicator or any derivative |
//|    that you create from it.  It was released freely, please keep |
//|    it free.                                                      |
//|                                                                  |
//| 2. If you make alterations, please don't release a new version   |
//|    using the name "SS_SupportResistance".  Either release it     |
//|    using a new name, or contact me about getting your changes    |
//|    included in my indicator (andrewsumner@yahoo.com).            |
//|                                                                  |
//| 3. If you make a killer EA based on this indicator, please do me |
//|    a favour and send me a copy :)                                |
//|                                                                  |
//| My thanks to Enrico "brax64" Carpita for his help in completing  |
//| the zone.show.info text positioning code.                        |
//+------------------------------------------------------------------+

#property copyright "Copyright © 2012 Andrew Sumner"
#property link      ""

#property indicator_chart_window
#property indicator_buffers 4
#property indicator_color1 Red
#property indicator_color2 Red
#property indicator_color3 DodgerBlue
#property indicator_color4 DodgerBlue

 int BackLimit   = 10000;
 int TimeFrame   = 0;
 string TimeString  = "0=Current, 60=H1, 240=H4, 1440=Day, 10080=Week, 43200=Month";

 color color.support.weak     = DarkSlateGray;
 color color.support.untested = SeaGreen;
 color color.support.verified = Green;
 color color.support.proven   = LimeGreen;
 color color.support.turncoat = OliveDrab;
 color color.resist.weak      = Indigo;
 color color.resist.untested  = Orchid;
 color color.resist.verified  = Crimson;
 color color.resist.proven    = Red;
 color color.resist.turncoat  = DarkOrange;

extern bool zone.show.weak  = true;
 double zone.fuzzfactor = 0.75;
 bool zone.solid = false;
 int zone.linewidth = 2;//1
 int zone.style = 0;
 bool zone.show.info    = true;
 int zone.label.shift  = 5;
 bool zone.show.alerts  = false;
 bool zone.alert.popups = false;
 bool zone.alert.sounds = false;
 int zone.alert.waitseconds = 300; 
 bool zone.merge = true;
extern bool zone.extend = false;

 bool fractals.show = false;
 double fractal.fast.factor = 3.0;
 double fractal.slow.factor = 6.0;
 bool SetGlobals = true;

double FastDnPts[], FastUpPts[];
double SlowDnPts[], SlowUpPts[];

double zone.hi[1000], zone.lo[1000];
int    zone.start[1000], zone.hits[1000], zone.type[1000], zone.strength[1000], zone.count = 0;
bool   zone.turn[1000];

#define ZONE_SUPPORT 1
#define ZONE_RESIST  2

#define ZONE_WEAK      0
#define ZONE_TURNCOAT  1
#define ZONE_UNTESTED  2
#define ZONE_VERIFIED  3
#define ZONE_PROVEN    4

#define UP_POINT 1
#define DN_POINT -1

int time.offset = 0;

int init()
{
   IndicatorBuffers(4);

   SetIndexBuffer(0, SlowDnPts);
   SetIndexBuffer(1, SlowUpPts);
   SetIndexBuffer(2, FastDnPts);
   SetIndexBuffer(3, FastUpPts);

   if (fractals.show == true)
   {
      SetIndexStyle(0, DRAW_ARROW, 0, 3);
      SetIndexStyle(1, DRAW_ARROW, 0, 3);
      SetIndexStyle(2, DRAW_ARROW, 0, 1);
      SetIndexStyle(3, DRAW_ARROW, 0, 1);
      SetIndexArrow(0, 218);
      SetIndexArrow(1, 217);
      SetIndexArrow(2, 218);
      SetIndexArrow(3, 217);
   }
   else
   {
      SetIndexStyle(0, DRAW_NONE);
      SetIndexStyle(1, DRAW_NONE);
      SetIndexStyle(2, DRAW_NONE);
      SetIndexStyle(3, DRAW_NONE);
   }

   if (TimeFrame != 1 && TimeFrame != 5 && TimeFrame != 15 &&
       TimeFrame != 60 && TimeFrame != 240 && TimeFrame != 1440 &&
       TimeFrame != 10080 && TimeFrame != 43200)
      TimeFrame = 0;

   if (TimeFrame < Period())
      TimeFrame = Period();

   return(0);
}

int deinit()
{
   DeleteZones();
   DeleteGlobalVars();
   return(0);
}

int start()
{
   if (NewBar() == true)
   {
      int old_zone.count = zone.count;

      FastFractals();
      SlowFractals();
      DeleteZones();
      FindZones();
      DrawZones();
      if (zone.count < old_zone.count)
         DeleteOldGlobalVars(old_zone.count);
   }

   if (zone.show.info == true)
   {
      for (int i=0; i<zone.count; i++)
      {
         if (zone.strength[i] == ZONE_WEAK && zone.show.weak == false)
         continue;
      
         string lbl;
         if (zone.strength[i] == ZONE_PROVEN)
            lbl = "Proven";
         else if (zone.strength[i] == ZONE_VERIFIED)
            lbl = "Verified";
         else if (zone.strength[i] == ZONE_UNTESTED)
            lbl = "Untested";
         else if (zone.strength[i] == ZONE_TURNCOAT)
            lbl = "Turncoat";
         else
            lbl = "Weak";

         if (zone.type[i] == ZONE_SUPPORT)
            lbl = lbl + " Support";
         else
            lbl = lbl + " Resistance";

         if (zone.hits[i] > 0 && zone.strength[i] > ZONE_UNTESTED)
         {
            if (zone.hits[i] == 1)
               lbl = lbl + ", Test Count=" + zone.hits[i];
            else
               lbl = lbl + ", Test Count=" + zone.hits[i];
         }

         int adjust.hpos;
         int wbpc = WindowBarsPerChart();
         int k;
         
         k = Period() * 60 + (20 + StringLen(lbl));
         
         if (wbpc < 80)  
            adjust.hpos = Time[0] + k * 4;
         else if (wbpc < 125)  
            adjust.hpos = Time[0] + k * 8;
         else if (wbpc < 250)
            adjust.hpos = Time[0] + k * 15;
         else if (wbpc < 480)
            adjust.hpos = Time[0] + k * 29;
         else if (wbpc < 950)
            adjust.hpos = Time[0] + k * 58;
         else
            adjust.hpos = Time[0] + k * 115;
         
         //

         int shift = k * zone.label.shift;
         double vpos = zone.hi[i] - (zone.hi[i] - zone.lo[i]) / 2;

         string s = "SSSR#"+i+"LBL";
         ObjectCreate(s, OBJ_TEXT, 0, 0, 0);
         ObjectSet(s, OBJPROP_TIME1, adjust.hpos + shift);
         ObjectSet(s, OBJPROP_PRICE1, vpos);
         ObjectSetText(s, StringRightPad(lbl, 36, " "), 8, "Courier New");
      }
   }

   CheckAlerts();

   return(0);
}

void CheckAlerts()
{
   static int lastalert = 0;

   if (zone.show.alerts == false)
      return;

   if (Time[0] - lastalert > zone.alert.waitseconds)
      if (CheckEntryAlerts() == true)
         lastalert = Time[0];
}

bool CheckEntryAlerts()
{
   // check for entries
   for (int i=0; i<zone.count; i++)
   {
      if (Close[0] >= zone.lo[i] && Close[0] < zone.hi[i])
      {
         if (zone.show.alerts == true)
         {
            if (zone.alert.popups == true)
            {
               if (zone.type[i] == ZONE_SUPPORT)
                  Alert(Symbol() + TimeFrameToString(TimeFrame) + ": Support Zone Entered");
               else
                  Alert(Symbol() + TimeFrameToString(TimeFrame) + ": Resistance Zone Entered");
            }

            if (zone.alert.sounds == true)
               PlaySound("alert.wav");
         }

         return(true);
      }
   }

   return(false);
}

void DeleteGlobalVars()
{
   if (SetGlobals == false)
      return;

   GlobalVariableDel("SSSR_Count_"+Symbol()+TimeFrame);
   GlobalVariableDel("SSSR_Updated_"+Symbol()+TimeFrame);

   int old_count = zone.count;
   zone.count = 0;
   DeleteOldGlobalVars(old_count);
}

void DeleteOldGlobalVars(int old_count)
{
   if (SetGlobals == false)
      return;

   for (int i=zone.count; i<old_count; i++)
   {
      GlobalVariableDel("SSSR_HI_"+Symbol()+TimeFrame+i);
      GlobalVariableDel("SSSR_LO_"+Symbol()+TimeFrame+i);
      GlobalVariableDel("SSSR_HITS_"+Symbol()+TimeFrame+i);
      GlobalVariableDel("SSSR_STRENGTH_"+Symbol()+TimeFrame+i);
      GlobalVariableDel("SSSR_AGE_"+Symbol()+TimeFrame+i);
   }
}

void FindZones()
{
   int i, j, shift, bustcount=0, testcount = 0;
   double hival, loval;
   bool turned = false, hasturned = false;

   double temp.hi[1000], temp.lo[1000];
   int    temp.start[1000], temp.hits[1000], temp.strength[1000], temp.count = 0;
   bool   temp.turn[1000], temp.merge[1000];
   int merge1[1000], merge2[1000], merge.count = 0;

   // iterate through zones from oldest to youngest (ignore recent 5 bars),
   // finding those that have survived through to the present...
   for (shift=MathMin(iBars(NULL, TimeFrame)-1, BackLimit); shift>5; shift--)
   {
      double atr = iATR(NULL, TimeFrame, 7, shift);
      double fu = atr/2 * zone.fuzzfactor;
      bool isWeak;
      bool touchOk = false;
      bool isBust = false;
      double close = iClose(NULL, TimeFrame, shift);
      double high  = iHigh(NULL, TimeFrame, shift);
      double low   = iLow(NULL, TimeFrame, shift);
      double hi_i;
      double lo_i;

      if (FastUpPts[shift] > 0.001)
      {
         // a zigzag high point
         isWeak = true;
         if (SlowUpPts[shift] > 0.001)
            isWeak = false;

         hival = high;
         if (zone.extend == true)
            hival += fu;

         loval = MathMax(MathMin(close, high-fu), high-fu*2);
         turned = false;
         hasturned = false;
         isBust = false;

         bustcount = 0;
         testcount = 0;

         for (i=shift-1; i>=0; i--)
         {
            hi_i = iHigh(NULL, TimeFrame, i);
            lo_i = iLow(NULL, TimeFrame, i);

            if ((turned == false && FastUpPts[i] >= loval && FastUpPts[i] <= hival) ||
                (turned == true && FastDnPts[i] <= hival && FastDnPts[i] >= loval))
            {
               // Potential touch, just make sure its been 10+candles since the prev one
               touchOk = true;
               for (j=i+1; j<i+11; j++)
               {
                  if ((turned == false && FastUpPts[j] >= loval && FastUpPts[j] <= hival) ||
                      (turned == true && FastDnPts[j] <= hival && FastDnPts[j] >= loval))
                  {
                     touchOk = false;
                     break;
                  }
               }

               if (touchOk == true)
               {
                  // we have a touch.  If its been busted once, remove bustcount
                  // as we know this level is still valid & has just switched sides
                  bustcount = 0;
                  testcount++;
               }
            }

            if ((turned == false && hi_i > hival) ||
                (turned == true && lo_i < loval))
            {
               // this level has been busted at least once
               bustcount++;

               if (bustcount > 1 || isWeak == true)
               {
                  // busted twice or more
                  isBust = true;
                  break;
               }

               if (turned == true)
                  turned = false;
               else if (turned == false)
                  turned = true;

               hasturned = true;

               // forget previous hits
               testcount = 0;
            }
         }

         if (isBust == false)
         {
            // level is still valid, add to our list
            temp.hi[temp.count] = hival;
            temp.lo[temp.count] = loval;
            temp.turn[temp.count] = hasturned;
            temp.hits[temp.count] = testcount;
            temp.start[temp.count] = shift;
            temp.merge[temp.count] = false;
            
            if (testcount > 3)
               temp.strength[temp.count] = ZONE_PROVEN;
            else if (testcount > 0)
               temp.strength[temp.count] = ZONE_VERIFIED;
            else if (hasturned == true)
               temp.strength[temp.count] = ZONE_TURNCOAT;
            else if (isWeak == false)
               temp.strength[temp.count] = ZONE_UNTESTED;
            else
               temp.strength[temp.count] = ZONE_WEAK;

            temp.count++;
         }
      }
      else if (FastDnPts[shift] > 0.001)
      {
         // a zigzag low point
         isWeak = true;
         if (SlowDnPts[shift] > 0.001)
            isWeak = false;

         loval = low;
         if (zone.extend == true)
            loval -= fu;

         hival = MathMin(MathMax(close, low+fu), low+fu*2);
         turned = false;
         hasturned = false;

         bustcount = 0;
         testcount = 0;
         isBust = false;

         for (i=shift-1; i>=0; i--)
         {
            hi_i = iHigh(NULL, TimeFrame, i);
            lo_i = iLow(NULL, TimeFrame, i);

            if ((turned == true && FastUpPts[i] >= loval && FastUpPts[i] <= hival) ||
                (turned == false && FastDnPts[i] <= hival && FastDnPts[i] >= loval))
            {
               // Potential touch, just make sure its been 10+candles since the prev one
               touchOk = true;
               for (j=i+1; j<i+11; j++)
               {
                  if ((turned == true && FastUpPts[j] >= loval && FastUpPts[j] <= hival) ||
                      (turned == false && FastDnPts[j] <= hival && FastDnPts[j] >= loval))
                  {
                     touchOk = false;
                     break;
                  }
               }

               if (touchOk == true)
               {
                  // we have a touch.  If its been busted once, remove bustcount
                  // as we know this level is still valid & has just switched sides
                  bustcount = 0;
                  testcount++;
               }
            }

            if ((turned == true && hi_i > hival) ||
                (turned == false && lo_i < loval))
            {
               // this level has been busted at least once
               bustcount++;

               if (bustcount > 1 || isWeak == true)
               {
                  // busted twice or more
                  isBust = true;
                  break;
               }

               if (turned == true)
                  turned = false;
               else if (turned == false)
                  turned = true;

               hasturned = true;

               // forget previous hits
               testcount = 0;
            }
         }

         if (isBust == false)
         {
            // level is still valid, add to our list
            temp.hi[temp.count] = hival;
            temp.lo[temp.count] = loval;
            temp.turn[temp.count] = hasturned;
            temp.hits[temp.count] = testcount;
            temp.start[temp.count] = shift;
            temp.merge[temp.count] = false;

            if (testcount > 3)
               temp.strength[temp.count] = ZONE_PROVEN;
            else if (testcount > 0)
               temp.strength[temp.count] = ZONE_VERIFIED;
            else if (hasturned == true)
               temp.strength[temp.count] = ZONE_TURNCOAT;
            else if (isWeak == false)
               temp.strength[temp.count] = ZONE_UNTESTED;
            else
               temp.strength[temp.count] = ZONE_WEAK;

            temp.count++;
         }
      }
   }

   // look for overlapping zones...
   if (zone.merge == true)
   {
      merge.count = 1;
      int iterations = 0;
      while (merge.count > 0 && iterations < 3)
      {
         merge.count = 0;
         iterations++;

         for (i = 0; i < temp.count; i++)
            temp.merge[i] = false;

         for (i = 0; i < temp.count-1; i++)
         {
            if (temp.hits[i] == -1 || temp.merge[j] == true)
               continue;

            for (j = i+1; j < temp.count; j++)
            {
               if (temp.hits[j] == -1 || temp.merge[j] == true)
                  continue;

               if ((temp.hi[i] >= temp.lo[j] && temp.hi[i] <= temp.hi[j]) ||
                   (temp.lo[i] <= temp.hi[j] && temp.lo[i] >= temp.lo[j]) ||
                   (temp.hi[j] >= temp.lo[i] && temp.hi[j] <= temp.hi[i]) ||
                   (temp.lo[j] <= temp.hi[i] && temp.lo[j] >= temp.lo[i]))
               {
                  merge1[merge.count] = i;
                  merge2[merge.count] = j;
                  temp.merge[i] = true;
                  temp.merge[j] = true;
                  merge.count++;
               }
            }
         }

         // ... and merge them ...
         for (i=0; i<merge.count; i++)
         {
            int target = merge1[i];
            int source = merge2[i];

            temp.hi[target] = MathMax(temp.hi[target], temp.hi[source]);
            temp.lo[target] = MathMin(temp.lo[target], temp.lo[source]);
            temp.hits[target] += temp.hits[source];
            temp.start[target] = MathMax(temp.start[target], temp.start[source]);
            temp.strength[target] = MathMax(temp.strength[target], temp.strength[source]);
            if (temp.hits[target] > 3)
               temp.strength[target] = ZONE_PROVEN;

            if (temp.hits[target] == 0 && temp.turn[target] == false)
            {
               temp.hits[target] = 1;
               if (temp.strength[target] < ZONE_VERIFIED)
                  temp.strength[target] = ZONE_VERIFIED;
            }

            if (temp.turn[target] == false || temp.turn[source] == false)
               temp.turn[target] = false;
            if (temp.turn[target] == true)
               temp.hits[target] = 0;

            temp.hits[source] = -1;
         }
      }
   }

   // copy the remaining list into our official zones arrays
   zone.count = 0;
   for (i=0; i<temp.count; i++)
   {
      if (temp.hits[i] >= 0 && zone.count < 1000)
      {
         zone.hi[zone.count]       = temp.hi[i];
         zone.lo[zone.count]       = temp.lo[i];
         zone.hits[zone.count]     = temp.hits[i];
         zone.turn[zone.count]     = temp.turn[i];
         zone.start[zone.count]    = temp.start[i];
         zone.strength[zone.count] = temp.strength[i];
         
         if (zone.hi[zone.count] < Close[4])
            zone.type[zone.count] = ZONE_SUPPORT;
         else if (zone.lo[zone.count] > Close[4])
            zone.type[zone.count] = ZONE_RESIST;
         else
         {
            for (j=5; j<1000; j++)
            {
               if (iClose(NULL, TimeFrame, j) < zone.lo[zone.count])
               {
                  zone.type[zone.count] = ZONE_RESIST;
                  break;
               }
               else if (iClose(NULL, TimeFrame, j) > zone.hi[zone.count])
               {
                  zone.type[zone.count] = ZONE_SUPPORT;
                  break;
               }
            }

            if (j == 1000)
               zone.type[zone.count] = ZONE_SUPPORT;
         }

         zone.count++;
      }
   }
}

void DrawZones()
{
   if (SetGlobals == true)
   {
      GlobalVariableSet("SSSR_Count_"+Symbol()+TimeFrame, zone.count);
      GlobalVariableSet("SSSR_Updated_"+Symbol()+TimeFrame, TimeCurrent());
   }

   for (int i=0; i<zone.count; i++)
   {
      if (zone.strength[i] == ZONE_WEAK && zone.show.weak == false)
         continue;

      string s = "SSSR#"+i+" Strength=";
      if (zone.strength[i] == ZONE_PROVEN)
         s = s + "Proven, Test Count=" + zone.hits[i];
      else if (zone.strength[i] == ZONE_VERIFIED)
         s = s + "Verified, Test Count=" + zone.hits[i];
      else if (zone.strength[i] == ZONE_UNTESTED)
         s = s + "Untested";
      else if (zone.strength[i] == ZONE_TURNCOAT)
         s = s + "Turncoat";
      else
         s = s + "Weak";

      ObjectCreate(s, OBJ_RECTANGLE, 0, 0, 0, 0, 0);
      ObjectSet(s, OBJPROP_TIME1, iTime(NULL, TimeFrame, zone.start[i]));
      ObjectSet(s, OBJPROP_TIME2, TimeCurrent());
      ObjectSet(s, OBJPROP_PRICE1, zone.hi[i]);
      ObjectSet(s, OBJPROP_PRICE2, zone.lo[i]);
      ObjectSet(s, OBJPROP_BACK, zone.solid);
      ObjectSet(s, OBJPROP_WIDTH, zone.linewidth);
      ObjectSet(s, OBJPROP_STYLE, zone.style);

      if (zone.type[i] == ZONE_SUPPORT)
      {
         // support zone
         if (zone.strength[i] == ZONE_TURNCOAT)
            ObjectSet(s, OBJPROP_COLOR, color.support.turncoat);
         else if (zone.strength[i] == ZONE_PROVEN)
            ObjectSet(s, OBJPROP_COLOR, color.support.proven);
         else if (zone.strength[i] == ZONE_VERIFIED)
            ObjectSet(s, OBJPROP_COLOR, color.support.verified);
         else if (zone.strength[i] == ZONE_UNTESTED)
            ObjectSet(s, OBJPROP_COLOR, color.support.untested);
         else
            ObjectSet(s, OBJPROP_COLOR, color.support.weak);
      }
      else
      {
         // resistance zone
         if (zone.strength[i] == ZONE_TURNCOAT)
            ObjectSet(s, OBJPROP_COLOR, color.resist.turncoat);
         else if (zone.strength[i] == ZONE_PROVEN)
            ObjectSet(s, OBJPROP_COLOR, color.resist.proven);
         else if (zone.strength[i] == ZONE_VERIFIED)
            ObjectSet(s, OBJPROP_COLOR, color.resist.verified);
         else if (zone.strength[i] == ZONE_UNTESTED)
            ObjectSet(s, OBJPROP_COLOR, color.resist.untested);
         else
            ObjectSet(s, OBJPROP_COLOR, color.resist.weak);
      }



      if (SetGlobals == true)
      {
         GlobalVariableSet("SSSR_HI_"+Symbol()+TimeFrame+i, zone.hi[i]);
         GlobalVariableSet("SSSR_LO_"+Symbol()+TimeFrame+i, zone.lo[i]);
         GlobalVariableSet("SSSR_HITS_"+Symbol()+TimeFrame+i, zone.hits[i]);
         GlobalVariableSet("SSSR_STRENGTH_"+Symbol()+TimeFrame+i, zone.strength[i]);
         GlobalVariableSet("SSSR_AGE_"+Symbol()+TimeFrame+i, zone.start[i]);
      }
   }
}

bool Fractal(int M, int P, int shift)
{
   if (TimeFrame > P)
      P = TimeFrame;
   
   P = P / TimeFrame*2 + MathCeil(P / TimeFrame / 2);
   
   if (shift < P)
      return(false);

   if (shift > iBars(Symbol(), TimeFrame)-P)
      return(false); 
   
   for (int i=1; i<=P; i++)
   {
      if (M == UP_POINT)
      {
         if (iHigh(NULL, TimeFrame, shift+i) > iHigh(NULL, TimeFrame, shift))
            return(false);
         if (iHigh(NULL, TimeFrame, shift-i) >= iHigh(NULL, TimeFrame, shift))
            return(false);     
      }
      if (M == DN_POINT)
      {
         if (iLow(NULL, TimeFrame, shift+i) < iLow(NULL, TimeFrame, shift))
            return(false);
         if (iLow(NULL, TimeFrame, shift-i) <= iLow(NULL, TimeFrame, shift))
            return(false);
      }        
   }
   return(true);   
}  

void FastFractals()
{
   int shift;
   int limit = MathMin(Bars-1, BackLimit);
   int P = TimeFrame * fractal.fast.factor;

   FastUpPts[0] = 0.0; FastUpPts[1] = 0.0;
   FastDnPts[0] = 0.0; FastDnPts[1] = 0.0;

   for (shift=limit; shift>1; shift--)
   {
      if (Fractal(UP_POINT, P, shift) == true)
         FastUpPts[shift] = iHigh(NULL, TimeFrame, shift);
      else
         FastUpPts[shift] = 0.0;

      if (Fractal(DN_POINT, P, shift) == true)
         FastDnPts[shift] = iLow(NULL, TimeFrame, shift);
      else
         FastDnPts[shift] = 0.0;
   }
}

void SlowFractals()
{
   int shift;
   int limit = MathMin(iBars(Symbol(), TimeFrame) - 1, BackLimit);
   int P = TimeFrame * fractal.slow.factor;

   SlowUpPts[0] = 0.0; SlowUpPts[1] = 0.0;
   SlowDnPts[0] = 0.0; SlowDnPts[1] = 0.0;

   for (shift=limit; shift>1; shift--)
   {
      if (Fractal(UP_POINT, P, shift) == true)
         SlowUpPts[shift] = iHigh(NULL, TimeFrame, shift);
      else
         SlowUpPts[shift] = 0.0;

      if (Fractal(DN_POINT, P, shift) == true)
         SlowDnPts[shift] = iLow(NULL, TimeFrame, shift);
      else
         SlowDnPts[shift] = 0.0;
   }
}

bool NewBar()
{
   static datetime LastTime = 0;
   if (iTime(NULL, TimeFrame, 0) != LastTime)
   {
      LastTime = iTime(NULL, TimeFrame, 0)+time.offset;
      return (true);
   }
   else
      return (false);
}

void DeleteZones()
{
   int len = 5;
   int i;

   while (i < ObjectsTotal())
   {
      string objName = ObjectName(i);
      if (StringSubstr(objName, 0, len) != "SSSR#")
      {
         i++;
         continue;
      }
      ObjectDelete(objName);
   }
}

string TimeFrameToString(int tf) //code by TRO
{
   string tfs;

   switch(tf)
   {
      case PERIOD_M1:
         tfs = "M1"  ;
         break;
      case PERIOD_M5:
         tfs = "M5"  ;
         break;
      case PERIOD_M15:
         tfs = "M15" ;
         break;
      case PERIOD_M30:
         tfs = "M30" ;
         break;
      case PERIOD_H1:
         tfs = "H1"  ;
         break;
      case PERIOD_H4:
         tfs = "H4"  ;
         break;
      case PERIOD_D1:
         tfs = "D1"  ;
         break;
      case PERIOD_W1:
         tfs = "W1"  ;
         break;
      case PERIOD_MN1:
         tfs = "MN";
   }

   return(tfs);
}

string StringRepeat(string str, int n = 1)
{
  string outstr = "";
  for(int i = 0; i < n; i++) outstr = outstr + str;
  return(outstr);
}

string StringRightPad(string str, int n=1, string str2=" ")
{
  return(str + StringRepeat(str2,n-StringLen(str)));
}